module LilBlaster
  module Protocol
    # The classic semi-proprietary remote control format
    class RC5 < Protocol
      # The plen for the header
      attr_reader :header
      # The plen for the zero value
      attr_reader :zero_value
      # The plen for the one value
      attr_reader :one_value
      # The preamble before the button press
      attr_reader :system_data
      # Whether to send a post bit
      attr_reader :post_bit
      # Trailing space length
      attr_reader :gap

      # How to format hex numbers for readability
      HEX_FORMAT = '%#.4x'.freeze
      # How to format binary numbers for length and readability
      BINARY_FORMAT = '%.16b'.freeze

      # Checks that there are three and only three distinct tuples in the +data+
      def self.identify(data)
        data.tuples.uniq.length == 4
      end

      # Takes in the +data+, ensures it passes the identity check, then returns an instance
      # based on interpreting the signal, and an integer representing the specific code sent
      def self.identify!(data)
        super(data)

        proto = new(extract_values(data))

        [proto, proto.plens_to_int(data.tuples[17..-2])]
      end

      # Compares +tr_one+ and +tr_two+ as bytestrings for equality. Can be used to compare
      # Transmissions with inexact pulse lengths for the same underlying data
      def self.same_data?(tr_one, tr_two)
        raise ArgumentError unless [tr_one, tr_two].all? { |t| t.is_a?(Transmission) }

        bytestring_for(tr_one) == bytestring_for(tr_two)
      end

      # Takes in +args+ for instance variables
      def initialize(args = {})
        %i[header zero_value one_value system_data post_bit gap].each do |sym|
          instance_variable_set(:"@#{sym}", args.fetch(sym))
        end
      end

      # Takes in an integer +data+, and constructs a transmission with a header, the encoded
      # system_data, and the encoded integer
      def call(data = 0x0000)
        raise ArgumentError unless data.is_a?(Integer) && (0x0000..0xFFFF).cover?(data)

        pulses = []
        pulses += header
        pulses += int_to_plens(system_data)
        pulses += int_to_plens(data)

        if post_bit
          pulses += post_bit_plen
        else
          pulses[-1] = gap
        end

        Transmission.new(data: pulses.flatten)
      end

      # Takes in an integer +data+ and outputs the system_data
      # and encoded integer joined as a bytestring
      def to_bytestring(data = 0x0000)
        [system_data, data].map { |d| binary_pad(d) }.reduce(&:+)
      end

      # Compares self to other, returning true if their object states match
      def ==(other)
        other.class == self.class && other.object_state == object_state
      end

      alias eql? ==

      # Uses the object_state's hash
      def hash
        object_state.hash
      end

      # Takes in an +int+ and converts it first to binary,
      # then to tuples based on the zero and one values
      def int_to_plens(int)
        binary_pad(int).chars.map do |ch|
          case ch
          when /0/
            zero_value
          when /1/
            one_value
          end
        end
      end

      # Takes in tuples +plens+ and converts them into a binary string first,
      # then to an integer based on the zero and one values
      def plens_to_int(plens)
        plens.map do |pl|
          case pl
          when one_value
            '1'
          when zero_value
            '0'
          end
        end.join.to_i(2)
      end

      private

      def post_bit_plen
        j = zero_value
        j[1] = gap
        j
      end

      # Formats a number +num+ as a 16 digit binary number
      def binary_pad(num)
        format(BINARY_FORMAT, num)
      end

      # Yields the variables to compare for object equality
      def object_state
        [header, zero_value, one_value, system_data]
      end

      class << self
        # Given a +transmission+, extracts the values from it and creates a bytestring
        def bytestring_for(transmission)
          ident = extract_values(transmission)

          transmission.tuples[1..-2].map { |plen| plen == ident[:zero_value] ? '0' : '1' }.join
        end

        private

        # Does the work of scanning the tuples within the +data+ and identifying the attributes
        def extract_values(data)
          plens = data.tuples.uniq

          init_args = {
            header: plens.max { |a, _b| a[1] },
            gap: plens.max { |_a, b| b[1] }[1],
            zero_value: plens.min
          }

          init_args[:one_value] = plens.find do |plen|
            next unless plen != init_args[:header] && plen != init_args[:zero_value]
            next if plen[1] == init_args[:gap]

            plen
          end

          init_args[:system_data] = extract_system_data(init_args, data)
          init_args[:pre_bit] = plens.all? { |pl| pl.length == 2 }

          init_args
        end

        # Takes in the current +args+ and +data+ to identify and convert the system_data
        def extract_system_data(args, data)
          datum = data.tuples[1..16]

          datum.map { |x| x == args[:zero_value] ? '0' : '1' }
               .join
               .to_i(2)
        end
      end
    end
  end
end
