require 'lil_blaster/protocol/mark_space_encoding'

module LilBlaster
  module Protocol
    # The classic semi-proprietary remote control format
    class Manchester < BaseProtocol
      include MarkSpaceEncoding

      # The preamble before the button press
      attr_reader :system_data
      # Whether to send a post bit
      attr_reader :post_bit

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
          data_range(transmission, 17..-2)
        end

        # Returns an integer representing the system_data in the +transmission+
        def system_data(transmission)
          data_range(transmission, 1..16)
        end

        private

        # Does the work of scanning the tuples within the +data+ and identifying the attributes
        def extract_values(data)
          plens = data.tuples.uniq

          init_args = extract_mark_values(data)
          init_args[:system_data] = data_range(data, 1..16, init_args)
          init_args[:post_bit] = plens.all? { |pl| pl.length == 2 }

          init_args
        end
      end

      # Takes in +args+ for instance variables
      def initialize(args = {})
        super()

        %i[header zero_value one_value system_data post_bit gap repeat_value].each do |sym|
          instance_variable_set(:"@#{sym}", args.fetch(sym, nil))
        end
      end

      # Takes in an integer +data+, and constructs a transmission with a header, the encoded
      # system_data, and the encoded integer. Optionally specify the number of +repititions+
      def encode(data = 0x0000, repititions = 1)
        raise ArgumentError unless data.is_a?(Integer) && (0x0000..0xFFFF).cover?(data)

        return data_transmission(data) if repititions == 1

        tr = [data_transmission(data)]

        tr += if repeat_value
                Array.new(repititions - 1) { repeat_transmission }
              else
                Array.new(repititions - 1) { data_transmission(data) }
              end

        tr.reduce(&:+)
      end

      # Takes in an integer +data+ and outputs the system_data
      # and encoded integer joined as a bytestring
      def to_bytestring(data = 0x0000)
        [system_data, data].map { |d| binary_pad(d) }.reduce(&:+)
      end

      # Returns a hash of the instance values for use elsewhere
      def export_options
        %i[gap header one_value zero_value system_data post_bit].map do |sy|
          [sy, public_send(sy)]
        end.to_h
      end

      # Allows for calling +mtd+ on the class if it exists
      def method_missing(mtd, *args)
        super unless self.class.respond_to?(mtd)

        self.class.public_send(mtd, *args)
      end

      # Politely override method_missing
      def respond_to_missing?(mtd, *)
        self.class.respond_to?(mtd) || super
      end

      # Yields the variables to compare for object equality
      def object_state
        [system_data, repeat_value, header, zero_value, one_value]
      end

      private

      # Provided +data+ to encode, creates a transmission doing so
      def data_transmission(data)
        pulses = []
        pulses += header.clone
        pulses += int_to_pulses(system_data)
        pulses += int_to_pulses(data)

        if post_bit
          pulses += post_bit_plen
        else
          pulses[-1][1] = gap
        end

        Transmission.new(data: pulses.flatten)
      end

      # Uses the +repeat_value+ to produce a transmission with the repeat code
      def repeat_transmission
        pulses = repeat_value.dup

        pulses += if post_bit
                    post_bit_plen
                  else
                    [1, gap.dup]
                  end

        Transmission.new(data: pulses.flatten)
      end
    end
  end
end
