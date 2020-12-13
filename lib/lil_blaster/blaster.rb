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

      # Sends Codex#call to the +codex+ with the +sym+ argument, then runs #transmit on the result
      def send_code(sym, args = {})
        dex = args.fetch(:codex, nil) || LilBlaster::Codex.default
        raise ArgumentError 'No codex provided' unless dex

        transmit dex.call(sym, args.fetch(:repetitions, 1))
      end

      # Takes in a Transmission +data+, and constructs and transmits waves. Uses blocking form
      # if +args+ is set, and returns true if successful.
      def transmit(data, args = {})
        _pin = pin unless pin
        mtd = args.fetch(:blocking, true) ? :transmit! : :transmit

        GPIO::Wave.public_send(mtd, data)
      end

      private

      # The underlying GPIO pin, id determined by LilBlaster.transmitter_pin
      def pin
        @pin ||= GPIO::Pin.new(LilBlaster.transmitter_pin, :output)
      end
    end
  end
end
