require 'observer'

module LilBlaster
  # The IR Transmitter module
  class Reader
    class << self
      include Observable

      # The basic methods available from the pin
      %i[on? off?].each { |symbol| define_method(symbol) { pin.send(symbol) } }

      # Minimum bound for length of a gap
      MIN_GAP = 15_000
      # Minimum bound for length of a code
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

      def continuous_scan(args = {})
        pin.start_callback(
          args.fetch(:callback_edge, :either),
          &method(:pin_callback)
        )

        if args[:observe_transmissions]
          add_transmission_observers(args[:observe_transmissions])
        elsif args[:observe_codes]
          add_code_observers(args[:observe_codes])
        end
      end

      def stop_scan
        pin.stop_callback
        @observe_transmissions = @observe_codes = nil
      end

      # Takes in +args+ and uses them to decode the transmissions in the +transmission_buffer+,
      # using a provided or default Codex
      def decode_transmissions(args = {})
        dex = args.fetch(:codex, nil) || Codex.default
        raise ArgumentError, 'No Codex Provided' unless dex

        codes = record(args).map do |trns|
          dex.key(dex.protocol.decode(trns).last)
        end

        args.fetch(:uniq, false) ? codes.uniq : codes
      end

      # A buffer of recorded transmissions
      def transmission_buffer
        @transmission_buffer ||= []
      end

      private

      # Handle passing in +args+ to limit the number of transmissions recorded
      def read_limit(args = {})
        return false unless args.key?(:first)

        limit = if args[:first].is_a?(Integer)
                  args[:first]
                else
                  1
                end

        buffer_offset >= limit
      end

      # Store the length of the +transmission_buffer+ for computation
      def lock_offset
        @offset = [transmission_buffer.length, 0].max
      end

      # Memoize a Time variable
      def start_timer
        @start_time = Time.now
      end

      # Subtracts the locked offset from the current transmission_buffer length
      def buffer_offset
        transmission_buffer.length - @offset
      end

      # Taking in +args+ for :seconds, returns a boolean based on whether the value
      # is positive and finite, and more time has ellapsed than it
      def timer_reached?(args = {})
        secs = args.fetch(:seconds, 3.0)
        limit = secs.finite? && secs.positive?

        limit && Time.now - @start_time > secs
      end

      # Syntax sugar. Calls Pin#start_callback passing a potential +callback_edge+ argument,
      # and the +pin_callback+ method as the code, runs the block, then calls Pin#stop_callback
      def reading_block(args = {}, &blk)
        pin.start_callback(args.fetch(:callback_edge, :either), &method(:pin_callback))
        blk.call
        pin.stop_callback
      end

      def add_code_observers(args)
        dex = args.fetch(:codex, nil) || Codex.default
        raise ArgumentError, 'No Codex provided' unless dex

        collect_observers(args)
      end

      def add_transmission_observers(args)
        @observe_transmissions = true
        collect_observers(args)
      end

      def collect_observers(args)
        args.each do |o|
          if o.is_a?(Method)
            add_observer(o.receiver, o.name)
          else
            add_observer(o)
          end
        end
      end

      def handle_notify_observers(count)
        return unless @observe_transmissions || @observe_codes

        changed

        notif = if @observe_transmissions
                  transmission_buffer.last(count)
                elsif @observe_codes
                  map_to_codes(transmission_buffer.last(count))
                end

        notify_observers(notif)
      end

      def map_to_codes(transmissions)
        dex = @observe_codes || Codex.default

        transmissions.map do |tr|
          dex.key(dex.protocol.decode(tr).last)
        end
      end

      # Using the ranges from +transmission_bound+, converts the pulses in the +pulse_buffer+
      # to Transmissions in the +transmission_buffer+, then clears the +pulse_buffer+
      def accum_pulses
        tr = transmission_bound.map { |rn| pulse_buffer[rn] }
                               .map { |dbf| Transmission.new(data: NoiseReducer.call(dbf, {})) }

        pulse_buffer.clear
        transmission_buffer.concat(tr)

        handle_notify_observers(tr.length)
      end

      # Scans the +pulse_buffer+ and splits it into discreet transmissions using the +MIN_GAP+
      # to determine the boundaries. Returns an array of range objects for segmenting
      def transmission_bound
        start_at = pulse_buffer.index { |x| x > MIN_CODE }
        splits = pulse_buffer.map.with_index { |n, x| n > MIN_GAP ? x : nil }.compact

        splits.unshift(start_at)

        splits[0..-2].map.with_index { |n, x| n..splits[x + 1] }
      end

      # Buffer of pulses for low level use in +pin_callback+
      def pulse_buffer
        @pulse_buffer ||= []
      end

      # The function to run as pin callback, which compares the current and
      # last +tick+ to each other and adds it to the +pulse_buffer+
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
end
