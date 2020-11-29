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
        reading_block(args) do
          loop do
            break if timer_reached?(args)
            break if read_limit(args)
          end
        end

        transmission_buffer.last(transmission_buffer.length - @offset)
      end

      # Starts continuously recording in another thread. If passed observe arguments,
      # will pass them on to the relevant add_*_observers method
      def continuous_scan(args = {})
        if args[:observe_transmissions]
          add_transmission_observers(args[:observe_transmissions])
        elsif args[:observe_codes]
          add_code_observers(args[:observe_codes])
        end

        resume_scan(args)
      end

      # Stops the callback function, but leaves observers and instance variables set
      def pause_scan
        pin.stop_callback
        @scanning = false
      end

      # Runs the callback function, whether or not observer variables are set
      def resume_scan(args = {})
        pin.start_callback(
          args.fetch(:callback_edge, :either),
          &method(:pin_callback)
        )

        @scanning = true
      end

      # Cancels a continuous scan, unsetting instance variables and deleting observers
      def stop_scan
        pin.stop_callback
        delete_observers
        @observe_transmissions = @observe_codes = @scanning = nil
      end

      # Returns a truthy value based on whether the scan is running. True if it is, false if it has
      # been paused, and nil if it is not
      def scanning?
        @scanning
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

      # Store the length of the +transmission_buffer+ for computation
      def freeze_for_reading
        @offset = [transmission_buffer.length, 0].max
        @start_time = Time.now
      end

      # Handle passing in +args+ to limit the number of transmissions recorded
      def read_limit(args = {})
        return false unless args.key?(:first)

        limit = if args[:first].is_a?(Integer)
                  args[:first]
                else
                  1
                end

        transmission_buffer.length - @offset >= limit
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
        freeze_for_reading
        blk.call
        pin.stop_callback
      end

      # Takes in a hash, with +args+ for codex and observers
      def add_code_observers(args)
        one_dex = args.fetch(:codex, nil) || Codex.default

        raise ArgumentError, 'No Codex provided' unless one_dex

        @observe_codes = one_dex

        obs = args.find { |x, _y| x.to_s =~ /observers?/ }

        return unless obs

        collect_observers(Array(obs.last))
      end

      # Takes in an array of +args+ which are observers
      def add_transmission_observers(args)
        @observe_transmissions = true

        if args.is_a?(Hash)
          obs = args.find { |x, _y| x.to_s =~ /observers?/ }
          return unless obs

          collect_observers(Array(obs.last))
        else
          collect_observers(Array(args))
        end
      end

      # Given an array of +args+, adds them as observers. Passing a Method
      # object sets the receiver and method name, update is the default
      def collect_observers(args)
        args.each do |o|
          if o.is_a?(Method)
            add_observer(o.receiver, o.name)
          else
            add_observer(o)
          end
        end
      end

      # Takes in a +transmission+ yielded by accum_pulses, and if we are observing
      # processes the data and notifies observers
      def handle_notify_observers(transmission)
        return unless @observe_transmissions || @observe_codes

        changed

        notif = if @observe_transmissions
                  transmission
                elsif @observe_codes
                  observe_map_to_code(transmission)
                end

        notify_observers(notif)
      end

      # Using the codex in observe_codex or the default, decodes the transmission
      # and returns its key from the Codex
      def observe_map_to_code(transmission)
        dex = @observe_codes || Codex.default
        dex.decode(transmission)
      end

      # Using the ranges from +transmission_bound+, converts the pulses in the +pulse_buffer+
      # to Transmissions in the +transmission_buffer+, then clears the +pulse_buffer+
      def accum_pulses
        tr = transmission_bound.map { |rn| pulse_buffer[rn] }
                               .map { |dbf| Transmission.new(data: NoiseReducer.call(dbf, {})) }

        pulse_buffer.clear
        transmission_buffer.concat(tr)
        granulate_notifications(tr.length)
      end

      # Given a length, individually calls notification for each transmission
      def granulate_notifications(len)
        if len == 1
          handle_notify_observers(transmission_buffer.last)
        elsif len.length > 1
          len.times do |i|
            handle_notify_observers(transmission_buffer[-(i + 1)])
          end
        end
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
