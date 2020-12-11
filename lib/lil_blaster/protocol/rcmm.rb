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
      # A customer ID for OEM mode
      attr_reader :customer_id

      # The pulse timings ratios for matching
      DUTY_CYCLES = [6, 10, 15, 16, 22, 28].freeze
      # Modes for basic operation
      TWELVE_BIT_MODES = %i[extended mouse keyboard gamepad].freeze
      # Modes for extended operation
      TWENTY_FOUR_BIT_MODES = %i[oem x_mouse x_keyboard x_gamepad].freeze

      class << self
        # Checks that the +data+ conforms to spec by checking against duty cycles
        def match?(data)
          return false unless data.data.uniq.length == DUTY_CYCLES.length + 1

          data.data
              .uniq
              .reject { |r| r == data.data.max }
              .sort
              .zip(DUTY_CYCLES)
              .map { |k| k.reduce(&:/) }
              .uniq
              .one?
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
          init_args = values || extract_mark_values(transmission)[:pulse_values]

          mode_one, mode_two = transmission.tuples[1..2].map do |pl|
            pulses_to_int([pl], init_args)
          end

          return TWELVE_BIT_MODES[mode_one] unless mode_one.zero?

          TWENTY_FOUR_BIT_MODES[mode_two]
        end

        # Returns an integer dependant on the value in the second bit of +transmission+
        def address_data(transmission, values = nil)
          init_args = values || extract_mark_values(transmission)[:pulse_values]
          md = mode_data(transmission, init_args)

          return unless %i[mouse keyboard gamepad].include?(md)

          pulses_to_int([transmission.tuples[2]], init_args)
        end

        def customer_id_data(transmission, values = nil)
          init_args = values || extract_mark_values(transmission)[:pulse_values]
          md = mode_data(transmission, init_args)

          return unless md == :oem

          pulses_to_int(transmission.tuples[4..6], init_args)
        end

        def command_data(transmission, values = nil)
          init_args = values || extract_mark_values(transmission)[:pulse_values]
          range = mode_data(transmission, init_args) == :oem ? 6..-2 : 3..-2

          pulses_to_int(transmission.tuples[range], init_args)
        end

        private

        # Extracts the mode
        def extract_values(data)
          init_args = extract_mark_values(data)

          init_args[:mode] = mode_data(data)
          init_args[:address] = address_data(data)
          init_args[:customer_id] = customer_id_data(data)

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

        rem_val = @pre_data.to_s(4)[2..-1].to_i(4)
        rem_val.zero? ? remove_instance_variable(:@pre_data) : @pre_data = rem_val
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
        if self.class.match?(transmission)
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
        pulses += int_to_pulses(@pre_data) if @pre_data
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
          mouse: [pulse_values[:one], int_to_pulses(address)].map(&:clone),
          keyboard: [pulse_values[:two], int_to_pulses(address)].map(&:clone),
          gamepad: [pulse_values[:three], int_to_pulses(address)].map(&:clone),
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
