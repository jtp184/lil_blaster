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

        ret.protocol = Protocol[proto_sym].new(protocol_options)
        ret
      end

      # Given a +str+, extracts the options from it with +parse_options+ and returns the hash
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
        handle_meta_options
        extract_codes(ctext)
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
        return unless flopts

        @matches[:protocol_flag] = flopts.map { |f| protocol_matchers[f] }.compact.first

        unless %i[RC5 NEC RCMM].include?(@matches[:protocol_flag])
          raise TypeError, "Unimplemented protocol `#{@matches[:protocol_flag] || 'none'}`"
        end

        @matches[:gap] = estimate_gap if flopts.include?('CONST_LENGTH')

        @matches[:carrier_wave_options] = if @matches[:frequency]
                                            { frequency: @matches[:frequency] }
                                          else
                                            {}
                                          end
      end

      # Reinterprets the gap as the difference between the gap and a standard transmission
      def estimate_gap
        bit_size = (@matches[:system_data_bits] || 0) + (@matches[:data_bits] || 0)

        tlen = []
        tlen << @matches[:header] if @matches[:header]
        tlen << Array.new(bit_size, @matches[:zero])
        tlen = tlen.flatten.reduce(&:+)

        @matches[:gap] - tlen
      end

      # Returns just the arguments needed for the protocol
      def protocol_options
        po = @matches.slice(
          :gap,
          :post_bit,
          :pre_data,
          :carrier_wave_options
        )

        po.merge(pulse_values: @matches.slice(
          :header,
          :repeat,
          :zero,
          :one,
          :two,
          :three
        ))
      end

      # Provides regex patterns to match against
      def matchers
        @matchers ||= {
          data_bits: /\bbits\s+(\d+)/i,
          flags: /flags\s+([^\s]+)/i,
          driver: /driver\s+([^\s]+)/,
          frequency: /frequency\s+(\d+)/i,
          gap: /gap\s+(\d+)/i,
          header: /header\s+(\d+)\s+(\d+)/i,
          one: /one\s+(\d+)\s+(\d+)/i,
          post_bit: /ptrail\s+(\d+)/i,
          remote_name: /name\s+([^\s]+)/i,
          repeat: /repeat\s+(\d+)\s+(\d+)/i,
          pre_data: /pre_data\s+(0x[0-9a-f]+)/i,
          pre_data_bits: /pre_data_bits\s+(\d+)/i,
          three: /three\s+(\d+)\s+(\d+)/i,
          two: /two\s+(\d+)\s+(\d+)/i,
          zero: /zero\s+(\d+)\s+(\d+)/i
        }
      end

      # Provide procs to use for formatting the values
      def formatters
        return @formatters if @formatters

        @formatters = {
          remote_name: ->(m) { m[1] },
          driver: ->(m) { m[1] },
          flags: ->(m) { m[1].split('|') }
        }

        %i[header zero one two three repeat].each do |sym|
          @formatters[sym] = ->(m) { m[1..2].map(&:to_i) }
        end

        %i[pre_data pre_data_bits data_bits post_bit].each do |sym|
          @formatters[sym] = ->(m) { Integer(m[1]) }
        end

        @formatters[:frequency] = ->(m) { Integer(m[1]) / 1000.0 }
        @formatters[:gap] = ->(m) { m[1].to_i }

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

      # Provides string matchers for flag options related to protocols
      def protocol_matchers
        @protocol_matchers ||= {
          'RAW_CODES' => :raw,
          'RC5' => :RC5,
          'RC6' => :RC6,
          'RCMM' => :RCMM,
          'SHIFT_ENC' => :RC5,
          'SPACE_ENC' => :NEC
        }
      end

      def proto_sym
        if %i[RC5 NEC].include?(@matches[:protocol_flag])
          :Manchester
        elsif @matches[:protocol_flag] == :RCMM
          :RCMM
        else
          :Manchester
        end
      end

      # Given a string +text+ and a +start_str+ and +end_str+ to search between, returns a range
      # which will capture the substring
      def substring_range(text, start_str, end_str)
        (text.index(start_str) + start_str.length)..(text.index(end_str) + end_str.length)
      rescue NoMethodError => e
        err_str = "Could not find '#{start_str}'..'#{end_str}' in string"
        not_found = text.index(start_str).nil? || text.index(end_str).nil?
        raise ArgumentError, err_str if not_found

        raise e
      end
    end
  end
end
