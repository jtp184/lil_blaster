module LilBlaster
  # The IR Transmitter module
  class Reader
    class << self
      # The basic methods available from the pin
      %i[on? off?].each { |symbol| define_method(symbol) { pin.send(symbol) } }

      MIN_GAP = 15_000
      MIN_CODE = 100

      # Blocks for a number of +seconds+, and returns blips. Takes in +args+ to pass down
      def record(args = {})
        offset = [transmission_buffer.length - 1, 0].max
        pin.start_callback(args.fetch(:callback_edge, :either), &method(:pin_callback))

        start = Time.now

        loop do
          break if Time.now - start > args.fetch(:seconds, 3.0)
          break if args.fetch(:single, false) || (transmission_buffer.length - offset).positive?
        end

        pin.stop_callback
        transmission_buffer[offset..-1]
      end

      def decode_transmissions(codex = nil)
        dex = codex || Codex.default
        raise ArgumentError, 'No Codex Provided' unless dex

        transmission_buffer.map do |trns|
          dex.key(dex.protocol.decode(trns).last)
        end
      end

      def pulse_buffer
        @pulse_buffer ||= []
      end

      def transmission_buffer
        @transmission_buffer ||= []
      end

      private

      def accum_pulses
        tr = transmission_bound.map { |rn| pulse_buffer[rn] }
                               .map { |dbf| Transmission.new(data: NoiseReducer.call(dbf, {})) }

        pulse_buffer.clear
        transmission_buffer.concat(tr)
      end

      def transmission_bound
        start_at = @pulse_buffer.index { |x| x > MIN_CODE }
        splits = @pulse_buffer.map.with_index { |n, x| n > MIN_GAP ? x : nil }.compact

        splits.unshift(start_at)

        splits[0..-2].map.with_index { |n, x| n..splits[x + 1] }
      end

      def pin_callback(tick, _level, _pin, _val)
        @last_tick ||= tick

        edge = tick - @last_tick

        pulse_buffer << edge

        accum_pulses if edge > MIN_GAP

        @last_tick = tick
      end

      # The underlying GPIO pin, id determined by LilBlaster.transmitter_pin
      def pin
        @pin ||= GPIO::Pin.new(LilBlaster.reader_pin)
      end
    end
  end

  # Used to smooth out the data in a transmission
  class NoiseReducer
    class << self
      # Takes the code +buffer+ and does math to smooth out the transmission passing +args+ down
      def call(buffer, args)
        return perform_on_pairs(buffer, args) if args.fetch(:pairs, true)

        repl = average_values(buffer, args)
        replace_values(buffer, repl)
      end

      # Takes the code +buffer+ and passes +args+ down, operating seperately on marks and spaces
      def perform_on_pairs(buffer, args)
        pairs = buffer.each_slice(2).to_a
        marks_and_spaces = [pairs.map(&:first), pairs.map(&:last)]

        replace = marks_and_spaces.map { |lens| average_values(lens, args) }

        replace_values(marks_and_spaces[0], replace[0]).zip(
          replace_values(marks_and_spaces[1], replace[1])
        ).flatten
      end

      # Uses the +replacements+ hash to map the +buffer+ array
      def replace_values(buffer, replacements)
        buffer.map do |val|
          replacements[val]
        end
      end

      # Given an array of +pulses+, tallies them up and uniquifies them
      # for group_values and weighted_averages, passing +args+ down
      def average_values(pulses, args)
        tally = pulses.each_with_object(Hash.new(0)) { |obj, mem| mem.tap { |m| m[obj] += 1 } }
        plens = tally.to_a.sort.to_h.keys

        weight_averages(group_values(plens, args.fetch(:tolerance, 200)))
      end

      # Takes in the integer +plens+, and a +tolerance+ and returns an array of arrays
      # where each value is within that tolerance of its neighbors.
      def group_values(plens, tolerance)
        plens.reduce([[]]) do |mem, obj|
          last_plen = mem.last.last

          mem << [] if !last_plen.nil? && obj - last_plen > tolerance

          mem.tap { |m| m.last << obj }
        end
      end

      # Takes in an array of arrays +groups+ sums and divides them, and then zips them into a hash
      # mapping each member of the originals to the new averaged value to replace it with
      def weight_averages(groups)
        avgs = groups.map { |x| x.reduce(&:+) / x.length }

        groups.zip(avgs).to_a.each_with_object({}) do |tuple, mem|
          vals, avg = tuple

          vals.each { |x| mem[x] = avg }
          mem
        end
      end
    end
  end
end
