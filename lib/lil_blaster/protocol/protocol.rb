module LilBlaster
  # Group together mechanisms for encoding / decoding transmissions
  module Protocol
    # Abstract base class for different protocols to give consistent interface
    class Protocol
      class << self
        # To be implemented by subclasses, takes in +_data+ and returns a true if the data matches
        # the protocol, a false otherwise
        def identify(_data)
          false
        end

        # Superclass implementation returns nil unless the +data+ passes #identify
        def identify!(data)
          return nil unless identify(data)
        end
      end

      # Superclass implementation ignores the +data+ and returns a blank transmission.
      # Subclasses should process the data according to protocol, and return a real transmission
      def to_transmission(_data)
        Transmission.new(data: [])
      end
    end
  end
end
