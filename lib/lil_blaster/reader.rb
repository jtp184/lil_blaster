module LilBlaster
  # The IR Transmitter module
  class Reader
    class << self
      # The basic methods available from the pin
      %i[on? off?].each { |symbol| define_method(symbol) { pin.send(symbol) } }

      # Blocks for a number of +seconds+, and records blips
      def record(seconds = 3.0)
        last_tick = nil
        buffer = []

        pin.start_callback(:either) do |tick, _level|
          last_tick ||= tick

          edge = tick - last_tick
          buffer << edge

          last_tick = tick
        end

        start = Time.now
        nil until Time.now - start > seconds

        pin.stop_callback
        buffer.tap(&:shift)
      end

      private

      # The underlying GPIO pin, id determined by LilBlaster.transmitter_pin
      def pin
        @pin ||= GPIO::Pin.new(LilBlaster.reader_pin)
      end
    end
  end
end
