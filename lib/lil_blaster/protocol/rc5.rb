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
      # The preamble before the button data
      attr_reader :pre_data

      # Checks that there are three and only three distinct tuples in the +data+
      def self.identify(data)
        data.tuples.uniq.length == 3
      end

      # Takes in the +data+, ensures it passes the identity check, and constructs an object
      def self.identify!(data)
        super(data)

        init_args = extract_values(data)

        [
          new(init_args),
          plens_to_int(identify_code(data), init_args[:zero_value], init_args[:one_value])
        ]
      end

      def initialize(args = {})
        @header = args.fetch(:header)
        @zero_value = args.fetch(:zero_value)
        @one_value = args.fetch(:one_value)
        @pre_data = args.fetch(:pre_data)
      end

      def to_transmission(data = 0x0000)
        raise ArgumentError unless data.is_a?(Integer) && (0x0000..0xFFFF).cover?(data)

        pulses = []
        pulses += header
        pulses += int_to_plens(pre_data)
        pulses += int_to_plens(data)

        Transmission.new(data: pulses.flatten)
      end

      def to_bytestring(data = 0x0000)
        pre_data.to_s(2) + data.to_s(2)
      end

      private

      def int_to_plens(int)
        int.to_s(2).chars.map do |ch|
          case ch
          when /0/
            zero_value
          when /1/
            one_value
          end
        end
      end

      def plens_to_int(plens)
        self.class.plens_to_int(plens, zero_value, one_value)
      end

      class << self
        def bytestring_for(transmission)
          ident = extract_values(transmission)

          transmission.tuples[1..-1].map { |plen| plen == ident[:zero_value] ? '0' : '1' }.join
        end

        private

        def extract_values(data)
          plens = data.tuples.uniq
          sums = plens.map { |x| x.reduce(&:+) }

          init_args = {
            header: plens[sums.index(sums.max)],
            zero_value: plens[sums.index(sums.min)]
          }

          init_args[:one_value] = (plens - init_args.values).first

          init_args[:pre_data] = plens_to_int(
            data.tuples[1..15],
            init_args[:zero_value],
            init_args[:one_value]
          )

          init_args
        end

        def plens_to_int(plens, zero, one)
          plens.map do |pl|
            case pl
            when one
              '1'
            when zero
              '0'
            end
          end.join.to_i(2)
        end

        def identify_code(data)
          tup = data.tuples
          tup.shift

          tup[16..-1]
        end
      end
    end
  end
end
