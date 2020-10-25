require 'ostruct'
require 'forwardable'

module LilBlaster
  # Handles the low level interfacing with the Pi
  module GPIO
    class << self
      # Takes the +on_pin+, +off_pin+, and +length+ and composes a pulse
      def pulse_converter(on_pin, off_pin, length)
        wavetuner.pulse(on_pin, off_pin, length)
      end

      # Exposes the waveform creation and execution interface
      def wavetuner
        connection.wave
      end

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

        unless direction == dir
          @direction = dir
          gpio_pin.mode = dir == :input ? 0 : 1
        end
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
