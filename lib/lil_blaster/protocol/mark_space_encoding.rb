module LilBlaster
  module Protocol
    # Provides common methods for protocols that use mark / space values for binary encoding
    module MarkSpaceEncoding
      # The plen for the header
      attr_reader :header
      # The plen for the zero value
      attr_reader :zero_value
      # The plen for the one value
      attr_reader :one_value
      # Trailing space length
      attr_reader :gap
      # Repeat code if utilized
      attr_reader :repeat_value

      # How to format hex numbers for readability
      HEX_FORMAT = '%#.4x'.freeze
      # How to format binary numbers for length and readability
      BINARY_FORMAT = '%.16b'.freeze
      # Max the gap out so that we don't end up with egregious results
      MAXIMUM_GAP = 120_000

      # The methods to extend onto the base class when included
      module ClassMethods
        # Takes in tuples +plens+ and converts them into a binary string first,
        # then to an integer based on the zero and one values
        def pulses_to_int(plens, zero, one)
          plens.map do |pl|
            case pl
            when one
              '1'
            when zero
              '0'
            end
          end.join.to_i(2)
        end

        # Does the work of scanning the tuples within the +data+ and identifying the attributes
        def extract_mark_values(data)
          plens = data.tuples.uniq

          init_args = {
            header: plens.max { |a, b| a[0] <=> b[0] },
            gap: [plens.max { |_a, b| b[1] }[1], MAXIMUM_GAP].min,
            zero_value: plens.min
          }

          init_args[:one_value] = plens.find do |plen|
            next unless plen != init_args[:header] && plen != init_args[:zero_value]
            next if plen[1] == init_args[:gap]

            plen
          end

          init_args
        end

        # Takes the +transmission+ and converts the tuples at +range+ into an integer.
        # +args+ to use for zero and one value can be passed
        def data_range(transmission, range, args = nil)
          args ||= extract_mark_values(transmission)

          pulses_to_int(transmission.tuples[range], args[:zero_value], args[:one_value])
        end
      end

      # Extends the +base_class+ with the ClassMethods upon inclusion
      def self.included(base_class)
        base_class.extend(ClassMethods)
      end

      private

      # Takes in an +int+ and converts it first to binary,
      # then to tuples based on the zero and one values
      def int_to_pulses(int)
        binary_pad(int).chars.map do |ch|
          case ch
          when /0/
            zero_value.clone
          when /1/
            one_value.clone
          end
        end
      end

      # Sends a post_bit, which is the mark with a gap sized space
      def post_bit_plen
        zero_value.clone.tap { |zv| zv[1] = gap }
      end

      # Formats a number +num+ as a 16 digit binary number
      def binary_pad(num)
        format(BINARY_FORMAT, num)
      end
    end
  end
end
