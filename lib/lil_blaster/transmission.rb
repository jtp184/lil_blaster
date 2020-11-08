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

    # Returns the data as 2-tuples containing a mark and space
    def tuples
      data.each_slice(2).to_a
    end

    # Predicate method for whether this transmission uses a carrierwave
    def carrier_wave?
      @carrier_wave
    end
  end
end
