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
      def get_multi_input(args = {})
        st = Time.now

        loop do
          break if timeout?(args.merge(start_time: st))

          pn = pins.find_all(&:on?)
          next if pn.empty?
          next unless pn.count >= args.fetch(:count, 1)

          return pn.map { |n| pin_val(n) }
        end
      end

      # Takes in +args+ for samples or seconds, loops and collects pin status.
      # Yields that status to a block if given, and returns the collection of presses
      def get_raw_input(args = {})
        st = Time.now
        presses = []

        loop do
          break if timeout?(args.merge(start_time: st))
          break if presses.length >= args.fetch(:samples, 3000)

          cur = Array(pins.find_all(&:on?).map { |n| pin_val(n) })
          yield cur if block_given?

          presses << cur
        end

        presses
      end

      private

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
