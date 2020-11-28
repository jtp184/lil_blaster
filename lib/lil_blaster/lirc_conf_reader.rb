module LilBlaster
  # Translates LIRC configs into codexes
  class LircConfReader
    class << self
      # Takes in the +text+ of a lirc.conf file and returns a codex version
      def call(text)
        ctext = text[substring_range(text, 'begin remote', 'end remote')]
        ret = Codex.new(extract_metadata(ctext).merge(codes: extract_codes(ctext)))
        ret.protocol = Protocol::Manchester.new(extract_protocol_options(ctext))

        ret
      end

      private

      # Scans the +text+ for the essential values to create the protocol
      def extract_protocol_options(text)
        opts = {}

        matchers.each do |key, regex|
          next unless text.match?(regex)

          opts[key] = formatters[key].call(text.match(regex))
        end

        opts
      end

      # Provides regex patterns to match against
      def matchers
        {
          header: /header\s+(\d+)\s+(\d+)/i,
          zero_value: /zero\s+(\d+)\s+(\d+)/i,
          one_value: /one\s+(\d+)\s+(\d+)/i,
          system_data: /pre_data\s+(0x[0-9a-f]+)/i,
          gap: /gap\s+(\d+)/i,
          repeat_value: /repeat\s+(\d+)\s+(\d+)/i,
          post_bit: /ptrail/
        }
      end

      # Provide procs to use for formatting the values
      def formatters
        {
          header: ->(m) { m[1..2].map(&:to_i) },
          zero_value: ->(m) { m[1..2].map(&:to_i) },
          one_value: ->(m) { m[1..2].map(&:to_i) },
          system_data: ->(m) { Integer(m[1]) },
          gap: ->(m) { m[1].to_i },
          repeat_value: ->(m) { m[1..2].map(&:to_i) },
          post_bit: ->(m) { !m.nil? }
        }
      end

      # Extracts the +remote_name+ out of the text
      def extract_metadata(text)
        {
          remote_name: text.match(/name\s+([^\s]+)/i).captures.first
        }
      end

      # Scans each line in the +text+ between 'begin codes' and 'end codes'
      # and converts them to a Symbol => Integer hash
      def extract_codes(text)
        code_rng = substring_range(text, 'begin codes', 'end codes')
        text[code_rng].scan(/([\w-]+)\s+(0x[0-9a-f]+)/i)
                      .to_h
                      .transform_keys(&:downcase)
                      .transform_keys { |s| Strings::Case.snakecase(s) }
                      .transform_keys(&:to_sym)
                      .transform_values { |v| Integer(v) }
      end

      # Given a string +text+ and a +start_str+ and +end_str+ to search between, returns a range
      # which will capture the substring
      def substring_range(text, start_str, end_str)
        (text.index(start_str) + start_str.length)..(text.index(end_str) + end_str.length)
      end
    end
  end
end
