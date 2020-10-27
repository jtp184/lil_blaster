require 'ostruct'
require 'forwardable'

module LilBlaster
  # Handles the low level interfacing with the Pi
  module GPIO
    class << self
      # Takes in the +pin_id+ and returns a gpio pin class
      def gpio_pin(pin_id)
        connection.gpio(pin_id)
      end

      # Memoizes and returns the hardware interface
      def connection
        @connection ||= driver.new
      end

      # Determines what to use as the driver, based on whether we have access to Pigpio.
      # Attempts to load it if possible, but not on non-pi hardware
      def driver
        if defined?(Pigpio)
          Pigpio
        elsif Gem.platforms.last.os == 'linux' && File.read('/proc/cpuinfo') =~ /Raspberry Pi/
          begin
            require 'pigpio'
            Pigpio
          rescue LoadError
            warn 'WARN: Pigpio is not defined, please require it.'
            nil
          end
        else
          warn 'WARN: Pigpio driver is not available on non Raspberry Pi hardware.'
          nil
        end
      end
    end

    # Models the hardware level signal processing
    class Wave
      class << self
        # Takes in +tuples+ of marks and spaces and returns an array of wave ids
        def tuples_to_wave(data)
          data.tuples.each.with_object([]) do |pulse, wids|
            mark, space = pulse

            wids << add_mark_wave(data, mark)
            wids << add_space_wave(space)
          end
        end

        # Syntax sugar for wavetuner#add_new
        def begin_wave
          wavetuner.add_new
        end

        # Syntax sugar for wavetuner#create
        def end_wave
          wavetuner.create
        end

        # Syntax sugar for wavetuner#add_generic, converts the array 3-tuples into pulses
        def add_to_wave(data)
          wavetuner.add_generic(data.map { |x| wavetuner.pulse(*x) })
        end

        # Creates a carrier wave, taking arguments for the frequency,
        # gpio_pin, pulse_length, and cycle_length
        def carrier(args = {})
          gpio = args.fetch(:gpio_pin, LilBlaster.transmitter_pin)
          timer = 0

          math = cycle_math(args)

          math[:cycle_count].times.with_object([]) do |cy, wave|
            target = ((cy + 1) * math[:cycle]).round

            timer += math[:blink_length]
            delay = (target - timer)
            timer += delay

            wave << on_pulse(gpio)
            wave << off_pulse(gpio)
          end
        end

        # A pulse which turns +gpio_pin+ on for +length+
        def on_pulse(length = 1, gpio_pin = LilBlaster.transmitter_pin)
          [1 << gpio_pin, 0, length]
        end

        # A pulse which turns +gpio_pin+ off for +length+
        def off_pulse(length = 1, gpio_pin = LilBlaster.transmitter_pin)
          [0, 1 << gpio_pin, length]
        end

        # A pulse with a +length+ and no signal
        def empty_pulse(length = 1)
          [0, 0, length]
        end

        # Exposes the waveform creation and execution interface
        def wavetuner
          @wavetuner ||= GPIO.connection.wave
        end

        # Chains the waves with ids +wids+ together
        def chain_waves(wids)
          wavetuner.chain(wids)
        end

        # Clears the waves in the wavetuner
        def clear_waves
          wavetuner.clear
        end

        private

        # Takes in the Transmission +data+ and the specific mark +plen+ to add a pulse to the wave
        def add_mark_wave(data, plen)
          begin_wave

          mark_wave = if data.carrier_wave?
                        GPIO::Wave.carrier(data.carrier_wave_options.merge(length: plen))
                      else
                        [GPIO::Wave.on_pulse(plen)]
                      end

          add_to_wave(mark_wave)

          end_wave
        end

        # Takes in the +plen+ and generates an empty pulse of that length
        def add_space_wave(plen)
          begin_wave

          pause = GPIO::Wave.empty_pulse(plen)
          add_to_wave([pause])

          end_wave
        end

        # Tidy up the carrier function by breaking out the math here
        def cycle_math(args)
          ret = {}

          ret[:cycle] = args.fetch(:cycle_length, 1000.0).to_f / args.fetch(:frequency, 38.0)
          ret[:cycle_count] = (args.fetch(:length) / ret[:cycle]).round
          ret[:blink_length] = (ret[:cycle] / 2.0).round

          ret
        end
      end
    end

    # Models the pin as an object, simplifying the interface
    class Pin
      extend Forwardable

      # Which pin is in question
      attr_reader :id
      # Whether this pin is for input or output
      attr_reader :direction
      # The GPIO pin object to puppet
      attr_reader :gpio_pin
      # The currently configured callback, if any
      attr_reader :callback

      def_delegators :@gpio_pin, :read, :write, :mode

      # Takes in the +pin+ number and the +dir+ symbol for direction
      def initialize(pin, dir = :input)
        @id = pin
        @gpio_pin = GPIO.gpio_pin(id)

        self.direction = dir
      end

      # Sets the direction using the pin path direction file
      def direction=(dir)
        raise ArgumentError unless %i[input output].include?(dir)
        return if  direction == dir

        @direction = dir
        gpio_pin.mode = dir == :input ? 0 : 1
      end

      # Detect whether gpio_pin reads as 1
      def on?
        gpio_pin.read == 1
      end

      # Detect whether gpio_pin reads as 0
      def off?
        gpio_pin.read.zero?
      end

      # Writes a 1 to the gpio_pin
      def turn_on
        gpio_pin.write(1) if direction == :output
        self
      end

      # Writes a 0 to the gpio_pin
      def turn_off
        gpio_pin.write(0) if direction == :output
        self
      end

      # If on, turns off, and vice versa
      def toggle
        on? ? turn_off : turn_on
      end

      # Waits until the pin reads #on? or +timeout+ seconds have ellapsed
      def wait(timeout = nil)
        if timeout.nil?
          nil until on?
          true
        else
          start_time = Time.now

          timeup, pinon = nil

          loop do
            timeup = Time.now - start_time > timeout
            pinon = on?

            break if timeup || pinon
          end

          pinon
        end
      end

      # Takes in an +edge_sym+ for whether to trigger on rising, falling, or either, and
      # a +blk+ function to run for the callback, and commits it to an instance variable
      def start_callback(edge_sym, &blk)
        edge_num = case edge_sym
                   when :rising
                     0
                   when :falling
                     1
                   when :either
                     2
                   end

        @callback = gpio_pin.callback(edge_num, &blk)
        self
      end

      # Stops the callback stored on the pin object
      def stop_callback
        @callback.cancel
        @callback = nil
        self
      end
    end
  end
end
