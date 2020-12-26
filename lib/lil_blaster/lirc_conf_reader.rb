require 'numbers_in_words'

module LilBlaster
  # Translates LIRC configs into codexes
  class LircConfReader
    class << self
      # Takes in a +str+, either a lirc.conf file or its filepath, and returns a codex version
      def call(str)
        text = File.exist?(str) ? File.read(str) : str

        rblocks = substring_ranges(text, 'begin remote', 'end remote').map! do |r|
          parse(text[r])
          codexify
        end

        rblocks.one? ? rblocks.first : rblocks
      end

      # Given a +str+, extracts the options from it with +parse_options+ and returns the hash
      def parse(str)
        @matches = {}
        parse_options(str)
        @matches
      end

      private

      def codexify
        ret = Codex.new(
          remote_name: @matches[:remote_name],
          codes: {}.merge(@matches[:codes] || {}).merge(@matches[:raw_codes] || {})
        )

        ret.protocol = Protocol[proto_sym].new(protocol_options) unless proto_sym == :raw
        ret
      end

      # Takes in the +text+ and parses the matched config options out of it
      def parse_options(text)
        extract_conf_options(text)
        handle_meta_options
        handle_code_extracts(text)
      end

      # Scans the +text+ for the essential values to create the protocol
      def extract_conf_options(text)
        @matches = matchers.map.with_object({}) do |dict, obj|
          key, regex = dict

          next unless text.match?(regex)

          obj[key] = formatters[key].call(text.match(regex))
        end
      end

      # Extracts the codes and raw codes within +ctext+
      def handle_code_extracts(ctext)
        extract_codes(ctext)
        extract_raw_codes(ctext)
      end

      # Takes the flag options and runs transformations based on them
      def handle_meta_options
        flopts = @matches[:flags]

        @matches[:protocol_flag] = flopts.map { |f| protocol_matchers[f] }.compact.first if flopts

        unless %i[RC5 NEC RCMM raw].include?(@matches[:protocol_flag])
          str = "Unparsable conf format `#{@matches[:protocol_flag] || @matches[:driver] || 'nil'}`"
          raise TypeError, str
        end

        return unless flopts

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
        tlen << Array.new(bit_size, @matches[:zero] || 0)
        tlen = tlen.compact.flatten.reduce(&:+)

        @matches[:gap] - (tlen || 0)
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
        @matches[:codes] = text[code_rng].scan(/([\w\-+]+)\s+(0x[0-9a-f]+)/i)
                                         .to_h
                                         .transform_keys { |k| sym_for_code(k) }
                                         .transform_values { |v| Integer(v) }
                                         .merge(repeat_code: - 1)
      rescue ArgumentError => e
        raise e unless e.message =~ /^Could not find/

        nil
      end

      # Extracts the raw code blocks defined in +text+, and converts them to a transmission backed
      # Codex
      def extract_raw_codes(text)
        code_rng = substring_range(text, 'begin raw_codes', 'end raw_codes')
        @matches[:raw_codes] = text[code_rng].scan(/(?:name\s+)([\w\-+]+)[\s\n]+((\d+[\s\n]+)+)/i)
                                             .map { |a, b, c| [a, b + c] }
                                             .to_h
                                             .transform_keys { |k| sym_for_code(k) }
                                             .transform_values { |v| raw_code_block(v) }
      rescue ArgumentError => e
        raise e unless e.message =~ /^Could not find/

        nil
      end

      # Provides string matchers for flag options related to protocols
      def protocol_matchers
        @protocol_matchers ||= {
          'RAW_CODES' => :raw,
          'RC5' => :RC5,
          'RC6' => :RC6,
          'RCMM' => :RCMM,
          'SHIFT_ENC' => :RC5,
          'SPACE_ENC' => :NEC,
          'XMP' => :XMP
        }
      end

      # Determines what protocol to use based on protocol flag
      def proto_sym
        if %i[RC5 NEC].include?(@matches[:protocol_flag])
          :Manchester
        elsif %i[RCMM raw].include?(@matches[:protocol_flag])
          @matches[:protocol_flag]
        else
          :Manchester
        end
      end

      # Transforms the key symbol found in the config file into a rubyish symbol
      def sym_for_code(code)
        sym = code.gsub(/\+$/, 'up').gsub(/-$/, 'down')
        sym = Strings::Case.snakecase(sym)

        sym = sym.split(/^(x_)?(key_|btn_)/).last if sym.match?(/^(x_)?(key_|btn_)/)
        sym = sym.scan(/(\w+)(up|down)/).join('_') if sym.match?(/[a-z](up|down)$/)
        sym = NumbersInWords.in_words(sym.to_i) if sym.match?(/^\d+$/)
        sym.to_sym
      end

      # Collects all the plens in +raw+ and converts them to a transmission
      def raw_code_block(raw)
        Transmission.new(data: raw.scan(/\d+/).map { |val| Integer(val) })
      end

      public

      # Return an array of ranges within +text+ demarkated by +start_str+ and +end_str+
      def substring_ranges(text, start_str, end_str)
        marker = 0
        rngs = []

        until marker >= text.length.pred
          begin
            r = substring_range(text, start_str, end_str, marker)
            rngs << r
          rescue ArgumentError => e
            raise e unless e.message =~ /^Could not find/

            break
          end
          marker = rngs.last.end
        end

        rngs
      end

      private

      # Given a string +text+ and a +start_str+ and +end_str+ to search between, returns a range
      # which will capture the substring
      def substring_range(text, start_str, end_str, offset = nil)
        sarg = [start_str, offset].compact
        earg = [end_str, offset].compact

        sr = text.index(*sarg) + start_str.length
        er = text.index(*earg) + end_str.length
        sr..er
      rescue StandardError => e
        raise e unless e.is_a?(NoMethodError) || e.is_a?(TypeError)

        err_str = "Could not find '#{start_str}'..'#{end_str}' in string"
        not_found = text.index(*sarg).nil? || text.index(*earg).nil?
        raise ArgumentError, err_str if not_found

        raise e
      end
    end
  end
end
