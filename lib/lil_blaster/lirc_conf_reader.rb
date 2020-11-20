module LilBlaster
  # Translates LIRC configs into codexes
  class LircConfReader
    class << self
      # Takes in the +text+ of a lirc.conf file and returns a codex version
      def call(text)
        ret = Codex.new(extract_metadata(text).merge(codes: extract_codes(text)))
        ret.protocol = Protocol::Manchester.new(extract_protocol_options(text))

        ret
      end

      private

      # Scans the +text+ for the essential values to create the protocol
      def extract_protocol_options(text)
        {
          header: text.match(/header\s+(\d+)\s+(\d+)/i)[1..2].map(&:to_i),
          zero_value: text.match(/zero\s+(\d+)\s+(\d+)/i)[1..2].map(&:to_i),
          one_value: text.match(/one\s+(\d+)\s+(\d+)/i)[1..2].map(&:to_i),
          system_data: Integer(text.match(/pre_data\s+(0x[0-9a-f]+)/i)[1]),
          gap: text.match(/gap\s+(\d+)/i)[1].to_i,
          post_bit: text.match?(/ptrail/)
        }
      end

      # Extracts the +remote_name+ out of the text
      def extract_metadata(text)
        {
          remote_name: text.match(/name ([^\s]+)/i).captures.first
        }
      end

      # Scans each line in the +text+ between 'begin codes' and 'end codes'
      # and converts them to a Symbol => Integer hash
      def extract_codes(text)
        start_at = text.index('begin codes') + 'begin codes'.length
        end_at = text.index('end codes') + 'end codes'.length

        text[start_at..end_at].scan(/([\w-]+)\s+(0x[0-9a-f]+)/i)
                              .to_h
                              .transform_keys(&:downcase)
                              .transform_keys { |s| Strings::Case.snakecase(s) }
                              .transform_keys(&:to_sym)
                              .transform_values { |v| Integer(v) }
      end
    end
  end
end
