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
        tidy_code(buffer.tap(&:shift))
      end

      private

      def tidy_code(pairs)
        [pairs.map(&:first), pairs.map(&:last)].map { |pulses| average_values(pulses) }
      end

      def average_values(pulses)
        tally = pulses.each_with_object(Hash.new(0)) { |obj, mem| mem.tap { |m| m[obj] += 1 } }
        plens = tally.to_a.sort.to_h.keys

        replace = weight_averages(group_values(plens))

        replace.map.with_index do |cd, ix|
          ix.even? ? replace[0][cd] : replacements[1][cd]
        end
      end

      def group_values(plens, tolerance = 200)
        plens.reduce([[]]) do |mem, obj|
          last_plen = mem.last.last

          if last_plen.nil?
          elsif obj - last_plen > tolerance
            mem << []
          end

          mem.tap { |m| m.last << obj }
        end
      end

      def weight_averages(groups)
        avgs = groups.map { |x| x.reduce(&:+) / x.length }

        groups.zip(avgs).to_a.each_with_object({}) do |tuple, mem|
          vals, avg = tuple

          vals.each { |x| mem[x] = avg }
          mem
        end
      end

      # The underlying GPIO pin, id determined by LilBlaster.transmitter_pin
      def pin
        @pin ||= GPIO::Pin.new(LilBlaster.reader_pin)
      end
    end
  end
end
