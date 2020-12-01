require 'lil_blaster/protocol/mark_space_encoding'

module LilBlaster
  module Protocol
    # The classic semi-proprietary remote control format
    class Manchester < BaseProtocol
      include MarkSpaceEncoding

      # The preamble before the button press
      attr_reader :system_data

      # The range where the system data is stored
      SYSTEM_DATA_RANGE = (1..16).freeze
      # The range where the command data is stored
      COMMAND_DATA_RANGE = (17..-2).freeze
      # How to format binary numbers for length and readability
      BINARY_FORMAT = '%.16b'.freeze

      class << self
        # Checks that there are four distinct tuples in the +data+, and 6 datums
        def match?(data)
          data.tuples.uniq.length == 4 && data.data.uniq.length == 6
        end

        # Takes in the +data+, ensures it passes the identity check, then returns an instance
        # based on interpreting the signal, and an integer representing the specific code sent
        def decode(data)
          return nil unless match?(data)

          proto = new(extract_values(data))

          [proto, command_data(data)]
        end

        # Returns an integer representing the command_data in the +transmission+
        def command_data(transmission)
          data_range(transmission, COMMAND_DATA_RANGE)
        end

        # Returns an integer representing the system_data in the +transmission+
        def system_data(transmission)
          data_range(transmission, SYSTEM_DATA_RANGE)
        end

        # Returns an array of the instance values to inspect
        def export_options
          super

          @export_options += %i[system_data]
        end

        private

        # Does the work of scanning the tuples within the +data+ and identifying the attributes
        def extract_values(data)
          init_args = extract_mark_values(data)
          init_args[:system_data] = data_range(data, 1..16, init_args)

          init_args
        end
      end

      # Handles the :pre_data within the +args+, after deferring to super
      def initialize(args = {})
        super

        return unless @pre_data

        @system_data = @pre_data
        remove_instance_variable(:@pre_data)
      end

      # Takes in an integer +data+, and constructs a transmission with a header, the encoded
      # system_data, and the encoded integer. Optionally specify the number of +repititions+
      def encode(data = 0x0000, repititions = 1)
        raise TypeError, 'data is not an integer' unless data.is_a?(Integer)
        raise IndexError, 'data is out of bounds' unless (-1..0xFFFF).cover?(data)

        return repeat_transmission if data == -1 && repititions == 1
        return repeat_transmission * repetitions if data == -1
        return data_transmission(data) if repititions == 1

        tr = [data_transmission(data)]

        tr += Array.new(repititions - 1) do
          pulse_values[:repeat] ? repeat_transmission : data_transmission(data)
        end

        tr.reduce(&:+)
      end

      # Instance level decode which takes the +transmission+ and detects if it is a standard
      # or repeat code. Mostly useful with codexes for detecting repeat codes
      def decode(transmission)
        if match?(transmission)
          self.class.decode(transmission)
        elsif recognize_repeat(transmission)
          [self, -1]
        end
      end

      # Takes in an integer +data+ and outputs the system_data
      # and encoded integer joined as a bytestring
      def to_bytestring(data = 0x0000)
        [system_data, data].map { |d| binary_pad(d) }.reduce(&:+)
      end

      # Returns :shift if pulses have the same first value, :space if they have the same last value
      # and nil if neither is the case
      def encoding
        same_first = pulse_values[:zero][0] == pulse_values[:one][0]
        same_last = pulse_values[:zero][1] == pulse_values[:one][1]

        if same_first
          :shift
        elsif same_last
          :space
        end
      end

      # Yields the variables to compare for object equality
      def object_state
        export_options.map { |o| instance_variable_get(:"@#{o}") }
      end

      private

      # Provided +data+ to encode, creates a transmission doing so
      def data_transmission(data)
        pulses = []
        pulses += pulse_values[:header].clone
        pulses += int_to_pulses(system_data)
        pulses += int_to_pulses(data)

        if post_bit
          pulses += post_bit_plen
        else
          pulses[-1][1] = gap
        end

        Transmission.new(data: pulses.flatten, carrier_wave: carrier_wave_options)
      end

      # Uses the +repeat+ to produce a transmission with the repeat code
      def repeat_transmission
        pulses = pulse_values[:repeat].dup

        pulses += if post_bit
                    post_bit_plen
                  else
                    [1, gap.dup]
                  end

        Transmission.new(data: pulses.flatten, carrier_wave: carrier_wave_options)
      end

      # Formats a number +num+ as a 16 digit binary number
      def binary_pad(num)
        format(BINARY_FORMAT, num)
      end

      # Takes in an +int+ and converts it first to binary,
      # then to tuples based on the zero and one values
      def int_to_pulses(int)
        binary_pad(int).chars.map do |ch|
          case ch
          when /0/
            pulse_values[:zero].clone
          when /1/
            pulse_values[:one].clone
          end
        end
      end
    end
  end
end
