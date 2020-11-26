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
        lock_offset
        start_timer

        reading_block(args) do
          loop do
            break if timer_reached?(args)
            break if read_limit(args)
          end
        end

        transmission_buffer.last(buffer_offset)
      end

      def decode_transmissions(args = {})
        dex = args.fetch(:codex, nil) || Codex.default
        raise ArgumentError, 'No Codex Provided' unless dex

        codes = record(args).map do |trns|
          dex.key(dex.protocol.decode(trns).last)
        end

        args.fetch(:uniq, false) ? codes.uniq : codes
      end

      def pulse_buffer
        @pulse_buffer ||= []
      end

      def transmission_buffer
        @transmission_buffer ||= []
      end

      private

      def read_limit(args = {})
        return false unless args.key?(:first)

        limit = if args[:first].is_a?(Integer)
                  args[:first]
                else
                  1
                end

        buffer_offset >= limit
      end

      def lock_offset
        @offset = [transmission_buffer.length, 0].max
      end

      def start_timer
        @start_time = Time.now
      end

      def buffer_offset
        transmission_buffer.length - @offset
      end

      def timer_reached?(args = {})
        secs = args.fetch(:seconds, 3.0)
        limit = secs.finite? && secs.positive?

        limit && Time.now - @start_time > secs
      end

      def reading_block(args = {}, &blk)
        pin.start_callback(args.fetch(:callback_edge, :either), &method(:pin_callback))
        blk.call
        pin.stop_callback
      end

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
