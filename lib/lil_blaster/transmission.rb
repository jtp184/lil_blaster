module LilBlaster
  # Format agnostic class that represents data encoded for IR broadcasting
  class Transmission
    # The underlying pulse length data
    attr_reader :data
    # The options for configuring a carrierwave (typically unnecessary)
    attr_reader :carrier_wave_options

    # Takes in +args+ for data, and carrier_wave
    def initialize(args = {})
      @data = args.fetch(:data, [])
      @carrier_wave = (args.fetch(:carrier_wave, true) != false)
      @carrier_wave_options = case args.fetch(:carrier_wave, nil)
                              when ->(o) { o.is_a?(Hash) }
                                args[:carrier_wave]
                              when ->(o) { o.is_a?(Float) }
                                { frequency: args[:carrier_wave] }
                              else
                                {}
                              end
    end

    # Uses the +original+ to duplicate attributes for the copy
    def initialize_copy(original)
      @data = original.data.dup
      @carrier_wave_options = original.carrier_wave_options.dup
    end

    # Returns the data as 2-tuples containing a mark and space
    def tuples
      data.each_slice(2).to_a
    end

    # Predicate method for whether this transmission uses a carrierwave
    def carrier_wave?
      @carrier_wave
    end

    # Returns the number of pulses in +data+
    def count
      data.count
    end

    # Returns the combined length of the transmission in micros, by summing +data+
    def length
      data.reduce(:+)
    end

    # Combines the data for this and +other+ transmission into a new transmission
    def +(other)
      self.class.new(
        data: data + other.data,
        carrier_wave: carrier_wave_options.merge(other.carrier_wave_options)
      )
    end

    # Returns a new transmission which repeats this data a number of times
    def *(other)
      raise TypeError, 'Must multiply by amount' unless other.is_a?(Numeric)

      self.class.new(
        data: Array.new(other, data).flatten,
        carrier_wave: carrier_wave_options.clone
      )
    end

    # Uses the +other+ object, a hash tuple as returned from NoiseReducer.replacement_matrix,
    # to create a new transmission that has been recalculated with it
    def %(other)
      unless other.is_a?(Array) && other.all? { |i| i.is_a?(Hash) } && other.length == 2
        raise TypeError, 'Needs to be a hash tuple'
      end

      pulses = data.map.with_index do |dta, ix|
        other[ix % 2][dta]
      end

      self.class.new(
        data: pulses,
        carrier_wave: carrier_wave_options.clone
      )
    end
  end
end
