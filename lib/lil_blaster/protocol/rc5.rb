require 'lil_blaster/protocol/mark_space_encoding'

module LilBlaster
  module Protocol
    # The classic semi-proprietary remote control format
    class RC5 < BaseProtocol
      include MarkSpaceEncoding

      # The preamble before the button press
      attr_reader :system_data
      # Whether to send a post bit
      attr_reader :post_bit

      class << self
        # Checks that there are four distinct tuples in the +data+, and 6 datums
        def identify(data)
          data.tuples.uniq.length == 4 && data.data.uniq.length == 6
        end

        # Takes in the +data+, ensures it passes the identity check, then returns an instance
        # based on interpreting the signal, and an integer representing the specific code sent
        def identify!(data)
          super(data)

          proto = new(extract_values(data))

          [proto, command_data(data)]
        end

        # Compares +tr_one+ and +tr_two+ as bytestrings for equality. Can be used to compare
        # Transmissions with inexact pulse lengths for the same underlying data
        def same_data?(tr_one, tr_two)
          raise ArgumentError unless [tr_one, tr_two].all? { |t| t.is_a?(Transmission) }

          bytestring_for(tr_one) == bytestring_for(tr_two)
        end

        # Given a +transmission+, extracts the values from it and creates a bytestring
        def bytestring_for(transmission)
          ident = extract_mark_values(transmission)

          transmission.tuples[1..-2].map { |plen| plen == ident[:zero_value] ? '0' : '1' }.join
        end

        # Returns an integer representing the command_data in the +transmission+
        def command_data(transmission)
          data_range(transmission, 17..-2)
        end

        # Returns an integer representing the system_data in the +transmission+
        def system_data(transmission)
          data_range(transmission, 1..16)
        end

        private

        # Does the work of scanning the tuples within the +data+ and identifying the attributes
        def extract_values(data)
          plens = data.tuples.uniq

          init_args = extract_mark_values(data)
          init_args[:system_data] = data_range(data, 1..16, init_args)
          init_args[:post_bit] = plens.all? { |pl| pl.length == 2 }

          init_args
        end
      end

      # Takes in +args+ for instance variables
      def initialize(args = {})
        super()

        %i[header zero_value one_value system_data post_bit gap].each do |sym|
          instance_variable_set(:"@#{sym}", args.fetch(sym))
        end
      end

      # Takes in an integer +data+, and constructs a transmission with a header, the encoded
      # system_data, and the encoded integer
      def call(data = 0x0000)
        raise ArgumentError unless data.is_a?(Integer) && (0x0000..0xFFFF).cover?(data)

        pulses = []
        pulses += header.clone
        pulses += int_to_pulses(system_data)
        pulses += int_to_pulses(data)

        if post_bit
          pulses += post_bit_plen
        else
          pulses[-1][1] = gap
        end

        Transmission.new(data: pulses.flatten)
      end

      # Takes in an integer +data+ and outputs the system_data
      # and encoded integer joined as a bytestring
      def to_bytestring(data = 0x0000)
        [system_data, data].map { |d| binary_pad(d) }.reduce(&:+)
      end

      # Returns a hash of the instance values for use elsewhere
      def export_options
        %i[gap header one_value zero_value system_data post_bit].map do |sy|
          [sy, public_send(sy)]
        end.to_h
      end

      # Allows for calling +mtd+ on the class if it exists
      def method_missing(mtd, *args)
        super unless self.class.respond_to?(mtd)

        self.class.public_send(mtd, *args)
      end

      # Politely override method_missing
      def respond_to_missing?(mtd, *)
        self.class.respond_to?(mtd) || super
      end

      private

      # Sends a post_bit, which is the mark with a gap sized space
      def post_bit_plen
        zero_value.clone.tap { |zv| zv[1] = gap }
      end

      # Yields the variables to compare for object equality
      def object_state
        [header, zero_value, one_value, system_data]
      end
    end
  end
end
