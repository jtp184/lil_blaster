require 'forwardable'

module LilBlaster
  # The IR Transmitter module
  class Blaster
    class << self
      extend Forwardable

      def_delegators :pin, :turn_on, :turn_off, :on?, :off?

      private

      # The underlying GPIO pin, id determined by LilBlaster.transmitter_pin
      def pin
        @pin ||= GPIO::Pin.new(LilBlaster.transmitter_pin, :output)
      end
    end
  end
end
