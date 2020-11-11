module LilBlaster
  module Protocol
    # Blink data in morse code
    class Morse < BaseProtocol
      # The dot length, in milis, to base timing data off of
      attr_reader :dot_length

      # A simple text file mapping the characters to dot/dashes
      MORSE = <<~DOC.freeze
        A B C D E F G H I J K L M N O P Q R S T U V W X Y Z 0 1 2 3 4 5 6 7 8 9 . , ? - / : ' - ) ; ( = @
        .- -... -.-. -.. . ..-. --. .... .. .--- -.- .-.. -- -. --- .--. --.- .-. ... - ..- ...- .-- -..- -.-- --.. ----- .---- ..--- ...-- ....- ..... -.... --... ---.. ----. .-.-.- --..-- ..--.. -....- -..-. ---... .----. -....- -.--.- -.-.- -.--. -...- .--.-.
      DOC

      # How long a dash is relative to dot_length
      DASH_LENGTH = 3
      # The inter-letter space relative to dot_length
      INTER_LETTER_SPACE = 1
      # The between letters of the same word space relative to dot_length
      BETWEEN_LETTER_SPACE = 3
      # The space between the last letter in a word and
      # the first lettter of the next, relative to dot_length
      WORD_SPACE = 7

      # Checks that there are only 3 unique pulse lengths in the +data+
      def self.match?(data)
        data_args = [data.data, data.tuples.map(&:first).min]
        places = data.data.max.to_s.length - 1

        reduced = fuzz(denoise(*data_args), places)

        checks = [
          INTER_LETTER_SPACE,
          BETWEEN_LETTER_SPACE,
          WORD_SPACE
        ].sort.map { |num| num * 10**places }

        reduced.uniq.sort == checks
      end

      # Identifies the transmission +data+ and returns an instance and the decoded data
      def self.decode(data)
        return nil unless super(data)

        dot_length = data.tuples.map(&:first).min
        proto = new(dot_length: dot_length)

        [proto, decode_dotdash_str(pulses_to_dotdash_str(data))]
      end

      # Takes in +args+ for dot length
      def initialize(args = {})
        super()

        @dot_length = args.fetch(:dot_length, 1000)
      end

      # Takes in a string +data+ and encodes it into a transmission of plens
      def encode(data = 'SOS')
        super(data)

        unless data.upcase.chars.all? { |c| c == ' ' || code_table.keys.include?(c) }
          raise ArgumentError, 'Invalid Characters'
        end

        plens = cluster_to_plens(string_to_cluster(data)).flatten

        Transmission.new(data: plens, carrier_wave: false)
      end

      # Access the class-level code table on the instance
      def code_table
        self.class.code_table
      end

      # Exports the dot_length as an option
      def export_options
        %i[dot_length].map { |sy| [sy, public_send(sy)] }.to_h
      end

      private

      # Takes a +cluster+ and loops through it to convert every mark of every letter of every word
      # of every cluster is appropriately turned into a plen
      def cluster_to_plens(cluster)
        cluster.map.with_index do |word, ix|
          multiple_words = cluster.length > 1
          last_word = ix == cluster.length.pred

          word.map.with_index do |letter, jx|
            last_letter = jx == word.length.pred

            letter.map.with_index do |mark, kx|
              last_mark = kx == letter.length.pred

              mark_to_plen(mark, decide_spacer(multiple_words, last_word, last_letter, last_mark))
            end
          end
        end
      end

      # Takes in the +mark+ and the +space_length+ and returns a plen tuple
      def mark_to_plen(mark, space_length = INTER_LETTER_SPACE)
        case mark
        when 0
          [dot_length, dot_length * space_length]
        when 1
          [dot_length * DASH_LENGTH, dot_length * space_length]
        end
      end

      # Takes in the +str+ and converts it into a cluster of marks, an array structure
      # where each word is given its own array, and each letter one within that
      def string_to_cluster(str)
        str.upcase
           .split(/\s+/)
           .map { |w| w.chars.map { |c| code_table[c] } }
      end

      # Takes in the arguments and decideds how long a space to generate
      def decide_spacer(multiple_words, last_word, last_letter, last_mark)
        last_letter_of_last_mark = last_mark && last_letter
        last_mark_of_letter = last_mark && !last_letter
        not_last_word_of_many = (multiple_words && !last_word)

        if last_letter_of_last_mark && not_last_word_of_many
          WORD_SPACE
        elsif last_mark_of_letter
          BETWEEN_LETTER_SPACE
        else
          INTER_LETTER_SPACE
        end
      end

      class << self
        # The code table, lazily created from the MORSE constant
        def code_table
          @code_table ||= MORSE.split("\n")
                               .map { |m| m.split(' ') }
                               .reduce(&:zip)
                               .to_h
                               .transform_values { |m| m.chars.map { |n| mark_to_int(n) } }
        end

        private

        # Takes in the +str+ of dots and dashes, splits and maps it
        def decode_dotdash_str(str)
          words = str.split('  ').map { |x| x.split(' ') }

          words.map do |letters|
            letters.map { |lt| code_table.key dotdash_to_nple(lt) }.join
          end.join(' ')
        end

        # Takes in the +data+ and converts it into a string of dots and dashes
        def pulses_to_dotdash_str(data)
          multiple = data.data.max.to_s.length - 1

          fuzz(data.data, multiple).each_slice(2)
                                   .map { |a, b| pulse_to_dotdash([a, b], 10**multiple) }
                                   .join
        end

        # Convert the characters of a +str+ into an array of 0 and 1
        def dotdash_to_nple(str)
          str.chars.map { |ch| ch == '.' ? 0 : 1 }
        end

        # Takes in a tuple +pulse+ and a decimal base +multi+ and converts a pulse to a character
        def pulse_to_dotdash(pulse, multi)
          case pulse
          when [INTER_LETTER_SPACE * multi, INTER_LETTER_SPACE * multi]
            '.'
          when [INTER_LETTER_SPACE * multi, BETWEEN_LETTER_SPACE * multi]
            '. '
          when [DASH_LENGTH * multi, INTER_LETTER_SPACE * multi]
            '-'
          when [DASH_LENGTH * multi, BETWEEN_LETTER_SPACE * multi]
            '- '
          when [INTER_LETTER_SPACE * multi, WORD_SPACE * multi]
            '.  '
          when [DASH_LENGTH * multi, WORD_SPACE * multi]
            '-  '
          end
        end

        # Calls the NoiseReducer on +pulses+ using +dot_length+ to factor tolerance
        def denoise(pulses, dot_length)
          LilBlaster::NoiseReducer.call(pulses, pairs: false, tolerance: dot_length * 1.5)
        end

        # Rounds all values in +plens+ to +places+
        def fuzz(plens, places)
          plens.map { |n| n.round(-places) }
        end

        # Binary encoding for dots and dashes as text
        def mark_to_int(dot_or_dash)
          dot_or_dash == '.' ? 0 : 1
        end
      end
    end
  end
end
