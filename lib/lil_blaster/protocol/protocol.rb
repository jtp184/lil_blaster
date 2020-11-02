module LilBlaster
  # Group together mechanisms for encoding / decoding transmissions
  module Protocol
    class << self
      # Identifies the +transmission+ and returns a symbol representation
      def identify(transmission)
        available_protocols.find { |_s, pr| pr.identify(transmission) == true }
                           .first
      end

      # Takes the +transmission+ and identifies it, then returns the Protocol#identify! result
      def identify!(transmission)
        available_protocols.find { |_s, pr| pr.identify(transmission) == true }
                           .last
                           .identify!(transmission)
      end

      # Takes in a +sym+ for the protocol, and uses const_get to return it
      def [](sym)
        lookup = constants.find { |c| c.to_s.downcase == sym.to_s.downcase }
        const_get(lookup)
      end

      # Constants on this class which are protocols, returned as symbol => protocl hash
      def available_protocols
        constants.reject { |c| c == :Protocol }
                 .map { |c| [c, const_get(c)] }
                 .select { |_s, c| c.ancestors.include?(LilBlaster::Protocol::Protocol) }
                 .to_h
      end
    end

    # Abstract base class for different protocols to give consistent interface
    class Protocol
      class << self
        # To be implemented by subclasses, takes in +_data+ and returns a true if the data matches
        # the protocol. Superclass always returns true
        def identify(_data)
          true
        end

        # Superclass implementation returns nil unless the +data+ passes #identify.
        # Subclasses should call super first to take advantage of this, then perform
        # processing as necessary to return an instance of the protocol, and a representation
        # of the decoded data as well.
        def identify!(data)
          return nil unless identify(data)

          [self, data]
        end
      end

      # Superclass implementation ignores the +data+ and returns a blank transmission.
      # Subclasses should process the data according to protocol, and return a real transmission
      def call(_data)
        Transmission.new(data: [])
      end

      alias create_transmission call

      # Compares self to other, returning true if their object states match
      def ==(other)
        other.class == self.class && other.object_state == object_state
      end

      alias eql? ==

      # Uses the object_state's hash
      def hash
        object_state.hash
      end

      # Superclass implementation. Subclasses should put their identifying attributes
      def object_state
        [self]
      end
    end
  end
end
