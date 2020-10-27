module LilBlaster
  # The IR Transmitter module
  class Reader
    class << self
      # The basic methods available from the pin
      %i[on? off?].each { |symbol| define_method(symbol) { pin.send(symbol) } }

      private

      # The underlying GPIO pin, id determined by LilBlaster.transmitter_pin
      def pin
        @pin ||= GPIO::Pin.new(LilBlaster.reader_pin, :output)
      end
    end
  end
end
