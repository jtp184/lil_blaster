module LilBlaster
  # Translates LIRC configs into codexes
  class LircConfReader
    class << self
      # Takes in a +str+, either a lirc.conf file or its filepath, and returns a codex version
      def call(str)
        parse(str)

        ret = Codex.new(
          remote_name: @matches[:remote_name],
          codes: @matches[:codes]
        )

        ret.protocol = Protocol::Manchester.new(protocol_options)
        ret
      end

      def parse(str)
        text = File.exist?(str) ? File.read(str) : str
        @matches = {}
        parse_options(text)
        @matches
      end

      private

      # Takes in the +text+ and parses the matched config options out of it
      def parse_options(text)
        ctext = text[substring_range(text, 'begin remote', 'end remote')]
        extract_conf_options(ctext)
        extract_codes(ctext)
        handle_meta_options
      end

      # Scans the +text+ for the essential values to create the protocol
      def extract_conf_options(text)
        @matches = matchers.map.with_object({}) do |dict, obj|
          key, regex = dict

          next unless text.match?(regex)

          obj[key] = formatters[key].call(text.match(regex))
        end
      end

      # Takes the +flopts+ and runs transformations based on them
      def handle_meta_options
        flopts = @matches[:flags]

        @matches[:gap] = estimate_gap if flopts.include?('CONST_LENGTH')
      end

      # Reinterprets the gap as the difference between the gap and a standard transmission
      def estimate_gap
        tlen = [@matches[:header], Array.new(32, @matches[:zero_value])].flatten.reduce(&:+)

        @matches[:gap] - tlen
      end

      # Returns just the arguments needed for the protocol
      def protocol_options
        @matches.slice(
          :header,
          :zero_value,
          :one_value,
          :system_data,
          :gap,
          :repeat_value,
          :post_bit
        )
      end

      # Provides regex patterns to match against
      def matchers
        @matchers ||= {
          header: /header\s+(\d+)\s+(\d+)/i,
          zero_value: /zero\s+(\d+)\s+(\d+)/i,
          one_value: /one\s+(\d+)\s+(\d+)/i,
          system_data: /pre_data\s+(0x[0-9a-f]+)/i,
          gap: /gap\s+(\d+)/i,
          repeat_value: /repeat\s+(\d+)\s+(\d+)/i,
          post_bit: /ptrail/,
          remote_name: /name\s+([^\s]+)/i,
          flags: /flags\s+([^\s]+)/i,
          system_data_bits: /pre_data_bits\s+(\d+)/i,
          data_bits: /\bbits\s+(\d+)/i
        }
      end

      # Provide procs to use for formatting the values
      def formatters
        return @formatters if @formatters

        @formatters = {
          remote_name: ->(m) { m[1] },
          flags: ->(m) { m[1].split('|') }
        }

        %i[header zero_value one_value repeat_value].each do |sym|
          @formatters[sym] = ->(m) { m[1..2].map(&:to_i) }
        end

        %i[system_data system_data_bits data_bits].each do |sym|
          @formatters[sym] = ->(m) { Integer(m[1]) }
        end

        @formatters[:gap] = ->(m) { m[1].to_i }
        @formatters[:post_bit] = ->(m) { !m.nil? }

        @formatters
      end

      # Scans each line in the +text+ between 'begin codes' and 'end codes'
      # and converts them to a Symbol => Integer hash
      def extract_codes(text)
        code_rng = substring_range(text, 'begin codes', 'end codes')
        @matches[:codes] = text[code_rng].scan(/([\w-]+)\s+(0x[0-9a-f]+)/i)
                                         .to_h
                                         .transform_keys(&:downcase)
                                         .transform_keys { |s| Strings::Case.snakecase(s) }
                                         .transform_keys(&:to_sym)
                                         .transform_values { |v| Integer(v) }
                                         .merge(repeat_code: - 1)
      end

      # Given a string +text+ and a +start_str+ and +end_str+ to search between, returns a range
      # which will capture the substring
      def substring_range(text, start_str, end_str)
        (text.index(start_str) + start_str.length)..(text.index(end_str) + end_str.length)
      end
    end
  end
end
