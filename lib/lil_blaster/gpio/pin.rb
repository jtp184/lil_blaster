require 'forwardable'

module LilBlaster
  module GPIO
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

      # Symbol to Integer hash for edge monitoring
      EDGES = { rising: 0, falling: 1, either: 2 }.freeze

      # Takes in the +pin+ number and the +dir+ symbol for direction
      def initialize(pin, dir = :input)
        @id = pin
        @gpio_pin = GPIO.connection.gpio(id)

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

      # Writes a 1 to the gpio_pin and returns self
      def turn_on
        gpio_pin.write(1) if direction == :output
        self
      end

      # Writes a 0 to the gpio_pin and returns self
      def turn_off
        gpio_pin.write(0) if direction == :output
        self
      end

      # If on, turns off, and vice versa, returning self
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
        @callback = gpio_pin.callback(EDGES[edge_sym], &blk)
        self
      end

      # Stops the callback stored on the pin object
      def stop_callback
        return self if @callback.nil?
        
        @callback.cancel
        @callback = nil
        self
      end
    end
  end
end
