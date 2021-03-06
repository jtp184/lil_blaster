module LilBlaster
  module Protocol
    # Provides common methods for protocols that use mark / space values for binary encoding
    module MarkSpaceEncoding
      # Trailing space length
      attr_reader :gap
      # What to send as a post bit
      attr_reader :post_bit

      # How to format hex numbers for readability
      HEX_FORMAT = '%#.4x'.freeze
      # Max the gap out so that we don't end up with egregious results
      MAXIMUM_GAP = 120_000
      # How close pulses have to be to be considered the same
      NOISE_TOLERANCE = 200

      # The methods to extend onto the base class when included
      module ClassMethods
        # Compares +tr_one+ and +tr_two+ by comparing their individual pulses with #close?
        # Can be used to compare Transmissions for the same underlying data
        def same_data?(tr_one, tr_two)
          unless [tr_one, tr_two].all? { |t| t.is_a?(Transmission) }
            raise TypeError, 'Not transmissions'
          end

          tr_one.data.map.with_index do |value, index|
            (value - tr_two.data[index]).abs < NOISE_TOLERANCE
          end.all?(true)
        end

        # Given a +transmission+, extracts the values from it and creates a bytestring
        def bytestring_for(transmission)
          ident = extract_mark_values(transmission)

          transmission.tuples[1..-2].map do |plen|
            plen == ident[:pulse_values][:zero] ? '0' : '1'
          end.join
        end

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
            gap: [plens.max { |_a, b| b[1] }[1], MAXIMUM_GAP].min,
            post_bit: plens[-2][0]
          }

          init_args[:pulse_values] = extract_pulse_values(init_args, plens)
          init_args
        end

        # Returns the pulse specific values, using +init_args+ to examine the +plens+
        def extract_pulse_values(init_args, plens)
          pulse_values = {
            header: plens.max { |a, b| a[0] <=> b[0] },
            zero: plens.min
          }

          pulse_values[:one] = plens.find do |plen|
            next unless plen != pulse_values[:header] && plen != pulse_values[:zero]
            next if plen[1] == init_args[:gap]

            plen
          end

          pulse_values
        end

        # Takes the +transmission+ and converts the tuples at +range+ into an integer.
        # +args+ to use for zero and one value can be passed
        def data_range(transmission, range, args = nil)
          args ||= extract_mark_values(transmission)

          pulses_to_int(
            transmission.tuples[range],
            args[:pulse_values][:zero],
            args[:pulse_values][:one]
          )
        end

        # Returns an array of the instance values to export
        def export_options
          super

          @export_options += %i[gap pulse_values post_bit]
        end
      end

      # Extends the +base_class+ with the ClassMethods upon inclusion
      def self.included(base_class)
        base_class.extend(ClassMethods)
      end

      # Lazy returns a tuple defaulting hash
      def pulse_values
        @pulse_values ||= Hash.new([0, 0])
      end

      # Returns true if the +transmission+ is identified to be a repeat signal
      def recognize_repeat(transmission)
        return false unless pulse_values.key?(:repeat)
        return false unless transmission.data.length == 4
        return false unless close?(transmission.data[0], pulse_values[:repeat][0])
        return false unless close?(transmission.data[1], pulse_values[:repeat][1])

        true
      end

      private

      # Compare two values for equality within +tolerance+
      def close?(val_one, val_two, tolerance = NOISE_TOLERANCE)
        (val_one - val_two).abs < tolerance
      end

      # Sends a post_bit, which is the mark with a gap sized space
      def post_bit_plen
        [post_bit, gap]
      end
    end
  end
end
