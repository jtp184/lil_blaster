module LilBlaster
  # The IR Transmitter module
  class Blaster
    class << self
      # The basic methods available from the pin
      %i[turn_on turn_off on? off?].each do |symbol|
        define_method(symbol) do
          val = pin.send(symbol)
          symbol.to_s =~ /\?$/ ? val : true
        end
      end

      private

      # The underlying GPIO pin, id determined by LilBlaster.transmitter_pin
      def pin
        @pin ||= GPIO::Pin.new(LilBlaster.transmitter_pin, :output)
      end
    end
  end
end
