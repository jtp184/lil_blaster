module LilBlaster
  # Handles interacting with the physical buttons on the HAT
  class Buttons
    class << self
      # Takes in +args+ for seconds, loops until that has ellapsed or a button has been pressed.
      # Returns that button's index, or nil if timeout was reached
      def get_input(args = {})
        st = Time.now

        loop do
          break if timeout?(args.merge(start_time: st))

          pn = pins.find(&:on?)
          next unless pn

          return pin_val(pn)
        end
      end

      # Takes in +args+ for seconds and a count of how many simultaneous button presses to watch
      # for, loops until they are found, and returns an array
      def get_chord_input(args = {})
        st = Time.now

        loop do
          break if timeout?(args.merge(start_time: st))

          pn = pins.find_all(&:on?)
          next if pn.empty?
          next unless pn.count >= args.fetch(:count, 1)

          return pn.map { |n| pin_val(n) }
        end
      end

      # Takes in +args+ for seconds, a count, and optional chords. Loops and collects pin status,
      # then returns the collection.
      def get_multi_input(args = {})
        st = Time.now
        presses = []

        pins.each do |pn|
          pn.start_callback(:rising) do
            next if timeout?(args.merge(start_time: st))
            next if presses.count == args.fetch(:count, Float::INFINITY)

            presses << pin_val(pn)
          end
        end

        loop do
          break if timeout?(args.merge(start_time: st))
          break if presses.count == args.fetch(:count, Float::INFINITY)
        end

        pins.each(&:stop_callback)

        presses
      end

      # Takes in +args+ for samples or seconds, loops and collects pin status.
      # Yields that status to a block if given, and returns the collection of presses
      def get_raw_input(args = {})
        st = Time.now
        presses = []

        loop do
          break if timeout?(args.merge(start_time: st))
          break if presses.length >= args.fetch(:samples, Float::INFINITY)

          cur = Array(pins.find_all(&:on?).map { |n| pin_val(n) })

          next if cur.empty? && !args.fetch(:spaces, false)

          yield cur if block_given?

          presses << cur
        end

        presses
      end

      # Retrieves a set callback for button indexed at +idx+
      def [](idx)
        callbacks[idx]
      end

      # Sets the callback function for button +idx+ to +func+, or stops and clears if it is nil
      def []=(idx, func)
        if func.nil?
          stop_callback(idx) && remove_callback(idx)
        else
          start_callback(idx, function: func)
        end
      end

      # Takes in a function argument to +args+ or a +blk+, sets the button at +idx+
      # to callback that function on a user provided callback_edge
      def start_callback(idx, args = {}, &blk)
        callbacks[idx] = args[:function] || blk

        pins[idx].start_callback(args.fetch(:callback_edge, :either), &callbacks[idx])
        callbacks[idx]
      end

      # Given a button +idx+, starts the callback set for that index
      def resume_callback(idx, args = {})
        raise ArgumentError, 'No current callback' unless callbacks[idx]

        pins[idx].start_callback(args.fetch(:callback_edge, :either), &callbacks[idx])
      end

      # Stops the callback running for button +idx+
      def stop_callback(idx)
        pins[idx].stop_callback
      end

      # Removes the callback for button +idx+
      def remove_callback(idx)
        callbacks[idx] = nil
      end

      private

      # An array to hold callback functions
      def callbacks
        @callbacks ||= Array.new(LilBlaster.button_pins.count)
      end

      # Takes in +args+ for seconds and start_time, returns true when the time has ellapsed
      def timeout?(args = {})
        return false unless args.key?(:seconds)

        secs = args.fetch(:seconds)
        limit = secs.finite? && secs.positive?

        limit && Time.now - args.fetch(:start_time) > secs
      end

      # Returns the index value of the passed +pin+
      def pin_val(pin)
        return @pin_val[pin.id] if @pin_val

        @pin_val = LilBlaster.button_pins.map.with_index { |n, x| [n, x] }.to_h
        @pin_val[pin.id]
      end

      # Maps the module defined pin numbers to Pin objects
      def pins
        @pins ||= LilBlaster.button_pins.map { |pn| GPIO::Pin.new(pn, :input) }
      end
    end
  end
end
