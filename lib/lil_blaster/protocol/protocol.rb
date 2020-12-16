module LilBlaster
  # Group together mechanisms for encoding / decoding transmissions
  module Protocol
    class << self
      # Identifies the +transmission+ and returns a symbol representation
      def identify(transmission)
        available_protocols.find { |_s, pr| pr.match?(transmission) == true }
                           .first
      end

      # Takes the +transmission+ and identifies it, then returns the Protocol#identify! result
      def identify!(transmission)
        proto = available_protocols.find { |_s, pr| pr.match?(transmission) == true }

        raise ArgumentError, 'Unidentifiable transmission' unless proto

        proto.last.decode(transmission)
      end

      # Takes in a +sym+ for the protocol, and searches for it in available protocols
      def [](sym)
        available_protocols.find { |s, _pr| s.to_s.downcase == sym.to_s.downcase }.last
      end

      # Descendents of the BaseProtocol class, returned as symbol => protocl hash
      def available_protocols
        BaseProtocol.descendants.map { |cl| [cl.to_sym, cl] }.to_h
      end
    end

    # Abstract base class for different protocols to give consistent interface
    class BaseProtocol
      class << self
        # All inheritors of this class
        attr_reader :descendants

        # To be implemented by subclasses, takes in +_data+ and returns a true if the data matches
        # the protocol. Superclass always returns true
        def match?(_data)
          true
        end

        # Superclass implementation returns nil unless the +data+ passes #match?.
        # Subclasses should call super first to take advantage of this, then perform
        # processing as necessary to return an instance of the protocol, and a representation
        # of the decoded data as well.
        def decode(data)
          return nil unless match?(data)

          [self, data]
        end

        # Returns a symbol interpretation of this class
        def to_sym
          name.split('::').last.to_sym
        end

        # An empty set to start with
        def export_options
          @export_options ||= Set.new
        end
      end

      # Callback method, when +subclass+ is created adds it to an internal array
      def self.inherited(subclass)
        super

        @descendants ||= []
        @descendants << subclass
      end

      # Auto initialize +args+ as instance variables
      def initialize(args = {})
        args.each do |k, v|
          instance_variable_set(:"@#{k}", v)
        end
      end

      # Memoize carrier wave options on the base class
      def carrier_wave_options
        @carrier_wave_options ||= {}
      end

      # Superclass implementation ignores the +data+ and returns a blank transmission.
      # Subclasses should process the data according to protocol, and return a real transmission
      def encode(_data)
        Transmission.new(data: [], carrier_wave: carrier_wave_options)
      end

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

      # Return a symbol representation of this class
      def to_sym
        self.class
            .name
            .split('::')
            .last
            .to_sym
      end

      # Accessible on the instance
      def export_options
        self.class.export_options
      end
    end
  end
end
