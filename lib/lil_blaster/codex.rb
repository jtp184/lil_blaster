require 'forwardable'
require 'psych'

module LilBlaster
  # Allows the storing, organizing and later playback of code sequences
  class Codex
    extend Forwardable

    attr_accessor :remote_name
    attr_accessor :protocol
    attr_accessor :path
    attr_reader :codes

    def_delegators :@codes, :[], :[]=, :key, :key?, :value?

    def initialize(args = {})
      @path = args.fetch(:path, "./#{args.fetch(:remote_name, 'Remote')}_codex.txt")

      load_from_existing_file && return if File.exist?(@path)

      @remote_name = args.fetch(:remote_name, 'Remote')
      @codes = args.fetch(:codes, {})

      proto = args.fetch(:protocol, nil)

      @protocol = if proto.is_a?(Symbol)
                    LilBlaster::Protocol[proto].new(args.fetch(:protocol_options, {}))
                  elsif proto.ancestors.include?(LilBlaster::Protocol::BaseProtocol)
                    proto
                  end
    end

    def call(key_sym)
      protocol.call self[key_sym]
    end

    def to_yaml
      Psych.dump(export_yaml)
    end

    def save_file
      File.open(@path, 'w+') { |f| f << to_yaml }
    end

    private

    def load_from_existing_file
      yml = parse_yaml(Psych.load(File.read(@path)))

      @remote_name = yml[:remote_name]
      @protocol = yml[:protocol].new(yml[:protocol_options])
      @codes = yml[:codes]
    end

    def export_yaml
      file = {}

      file[:metadata] = {}

      file[:metadata][:remote_name] = remote_name
      file[:metadata][:protocol] = protocol.to_sym
      file[:metadata][:protocol_options] = protocol.export_options

      file[:data] = codes

      file
    end

    def parse_yaml(yaml)
      {
        remote_name: yaml[:metadata][:remote_name],
        protocol: LilBlaster::Protocol[yaml[:metadata][:protocol]],
        protocol_options: yaml[:metadata][:protocol_options],
        codes: yaml[:data]
      }
    end
  end
end
