require 'lil_blaster/protocol/mark_space_encoding'
require 'lil_blaster/protocol/four_bit_data'

module LilBlaster
  module Protocol
    # The 4-bit encoded remote format
    class RCMM < BaseProtocol
      include MarkSpaceEncoding
      include FourBitData

      # The mode the device is operating in
      attr_reader :mode
      # The device address to avoid collisions
      attr_reader :address

      # Modes for basic operation
      TWELVE_BIT_MODES = %i[extended mouse keyboard gamepad].freeze
      # Modes for extended operation
      TWENTY_FOUR_BIT_MODES = %i[oem x_mouse x_keyboard x_gamepad].freeze

      class << self
        # Checks that the +data+ had five distinct tuples and 6 distinct datums
        def match?(data)
          data.tuples.uniq.length == 5 && data.data.uniq.length == 6
        end

        # Takes in the +data+, ensures it passes the identity check, then returns an instance
        # based on interpreting the signal, and an integer representing the specific code sent
        def decode(data)
          return nil unless match?(data)

          proto = new(extract_values(data))

          [proto, command_data(data)]
        end

        # Returns a symbol dependant on the values in the first two bits of +transmission+
        def mode_data(transmission, values = nil)
          init_args = values || extract_mark_values(transmission)

          mode_one, mode_two = transmission.tuples[1..2].map do |pl|
            plen_to_int(pl, init_args[:pulse_values])
          end

          return TWELVE_BIT_MODES[mode_one] unless mode_one.zero?

          TWENTY_FOUR_BIT_MODES[mode_two]
        end

        # Returns an integer dependant on the value in the second bit of +transmission+
        def address_data(transmission, values = nil)
          init_args = values || extract_mark_values(transmission)
          md = mode_data(transmission, init_args[:pulse_values])

          return unless %i[mouse keyboard gamepad].include?(md)

          transmission.tuples[3..4].map { |pl| pulses_to_int(pl, init_args[:pulse_values]) }
        end

        private

        # Extracts the mode
        def extract_values(data)
          init_args = extract_mark_values(data)

          init_args[:mode] = mode_data(data)
          init_args[:address] = address_data(data)

          init_args
        end
      end

      # Handles the :pre_data in +args+ to extract the mode and address
      def initialize(args = {})
        super

        return unless @pre_data

        sys_mode = @pre_data.to_s(4).chars.map(&:to_i)
        mode_one = TWELVE_BIT_MODES[sys_mode[0]]

        if mode_one == :extended
          @mode = TWENTY_FOUR_BIT_MODES[sys_mode[1]]
        else
          @mode = mode_one
          @address = sys_mode[1]
        end

        remove_instance_variable(:@pre_data)
      end

      # Encodes the integer +data+ constructing the transmission, and specifying a number of
      # +repititions+
      def encode(data = 0x0, repititions = 1)
        raise TypeError, 'data is not an integer' unless data.is_a?(Integer)
        raise IndexError, 'data is out of bounds' unless (-1..(2**24)).cover?(data)

        return repeat_transmission if data == -1 && repititions == 1
        return repeat_transmission * repititions if data == -1
        return data_transmission(data) if repititions == 1

        tr = [data_transmission(data)]

        tr += Array.new(repetitions - 1) do
          pulse_values[:repeat] ? repeat_transmission : data_transmission(data)
        end

        tr.reduce(&:+)
      end

      # Instance level decode which takes the +transmission+ and checks if it is a repeat
      def decode(transmission)
        if match?(transmission)
          self.class.decode(transmission)
        elsif recognize_repeat(transmission)
          [self, -1]
        end
      end

      # Export instance variable options
      def object_state
        export_options.map { |o| instance_variable_get(:"@#{o}") }
      end

      private

      # Takes in the +data+ and encodes a transmission
      def data_transmission(data)
        pulses = []
        pulses += pulse_values[:header].clone
        pulses += mode_transmission
        pulses += int_to_pulses(data)

        if post_bit
          pulses += post_bit_plen
        else
          pulses[-1][1] = gap
        end

        Transmission.new(data: pulses.flatten, carrier_wave: carrier_wave_options)
      end

      # Returns an array to construct the mode bits
      def mode_transmission
        {
          mouse: [pulse_values[:one], address].map(&:clone),
          keyboard: [pulse_values[:two], address].map(&:clone),
          gamepad: [pulse_values[:three], address].map(&:clone),
          oem: [pulse_values[:zero], pulse_values[:zero]].map(&:clone),
          x_keyboard: [pulse_values[:zero], pulse_values[:one]].map(&:clone),
          x_gamepad: [pulse_values[:zero], pulse_values[:two]].map(&:clone),
          x_mouse: [pulse_values[:zero], pulse_values[:three]].map(&:clone)
        }[mode]
      end

      # Takes in the +int+ and returns a pulse mapped value
      def int_to_pulses(int)
        int.to_s(4).chars.map do |ch|
          {
            '0' => pulse_values[:zero].clone,
            '1' => pulse_values[:one].clone,
            '2' => pulse_values[:two].clone,
            '3' => pulse_values[:three].clone
          }[ch]
        end
      end
    end
  end
end