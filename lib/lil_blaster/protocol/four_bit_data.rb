module LilBlaster
  module Protocol
    # Handles 4-bit data transmissions
    module FourBitData
      module ClassMethods
        def bytestring_for(transmission)
          ident = extract_mark_values(transmission)

          pulses_to_int(transmission.tuples, ident[:pulse_values]).to_s(4)
        end

        def pulses_to_int(plens, values)
          plens.map do |pl|
            case pl
            when values[:zero]
              '0'
            when values[:one]
              '1'
            when values[:two]
              '2'
            when values[:three]
              '3'
            end
          end.join.to_i(4)
        end

        def extract_mark_values(data)
          plens = data.tuples.uniq

          init_args = {
            gap: [plens.max { |_a, b| b[1] }[1], MAXIMUM_GAP].min,
            post_bit: plens[-2][0]
          }

          init_args[:pulse_values] = extract_pulse_values(plens)
          init_args
        end

        def extract_pulse_values(plens)
          pulse_values = { header: plens.max { |a, b| a[0] <=> b[0] } }

          remain = plens.uniq.reject { |pl| pl == pulse_values[:header] }

          pulse_values.merge(extract_data_values(remain))
        end

        def extract_data_values(plens)
          enc = [plens.map(&:first), plens.map(&:last)].map(&:uniq)
          enc = enc.index(enc.max)

          %i[zero one two three].zip(plens.sort { |a, b| a[enc] <=> b[enc] }).to_h
        end

        def data_range(transmission, range, args = nil)
          args ||= extract_mark_values(transmission)

          pulses_to_int(
            transmission.tuples[range],
            args[:pulse_values]
          )
        end
      end

      def self.included(base_class)
        base_class.extend(ClassMethods)
      end

      def plen_to_int(plen, args)
        case plen
        when args[:zero]
          0
        when args[:one]
          1
        when args[:two]
          2
        when args[:three]
          3
        end
      end
    end
  end
end
