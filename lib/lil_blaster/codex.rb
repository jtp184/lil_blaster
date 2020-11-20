require 'forwardable'
require 'psych'

module LilBlaster
  # Allows the storing, organizing and later playback of code sequences
  class Codex
    extend Forwardable

    # The designation for this remote
    attr_accessor :remote_name
    # What protocol to use to control the remote
    attr_accessor :protocol
    # The file path on the system to save to
    attr_accessor :path
    # The actual codes as a hash
    attr_reader :codes

    def_delegators :@codes, :[], :[]=, :key, :key?,
                   :value?, :keys, :each_key, :each_value,
                   :size, :include?, :fetch

    # Takes in a filepath +fpath+, returns a new instance if the file exists
    def self.load(fpath)
      raise LoadError, 'File not found' unless File.exist?(fpath)

      new(path: fpath)
    end

    # References the ConfigFile's remotes_dir key, scans all the entries in it and instantiates
    # any that match the pattern of codex files
    def self.autoload!
      return [] unless ConfigFile[:codexes_dir]

      dir = Pathname.new(ConfigFile[:codexes_dir]).expand_path

      return [] unless Dir.exist?(dir)

      entries = Dir.entries(dir)
                   .reject { |filename| filename =~ /^\.{1-2}$/ }
                   .map { |filename| [dir, filename].join('/') }

      @autoloaded = standard_codexes(entries)
      @autoloaded += lirc_confs(entries)
    end

    # Memoize the autoload! results which are unlikely to change
    def self.autoload
      return @autoloaded if @autoloaded

      autoload!
    end

    # Takes in the +yml_str+ and creates a new instance from it
    def self.from_yaml(yml_str)
      new(yaml: yml_str)
    end

    # Takes in +args+ and returns an instance. If :path is given, tries to load from it first
    def initialize(args = {})
      @path = args.fetch(:path, nil)

      load_yml = if args.key?(:yaml)
                   Psych.load args[:yaml]
                 elsif @path.nil?
                   nil
                 elsif File.exist?(@path)
                   Psych.load File.read(@path)
                 end

      load_from_existing_yaml(load_yml) && return if load_yml

      @remote_name = args.fetch(:remote_name, 'Remote')
      @path ||= "./#{@remote_name}_codex.yaml"
      @codes = args.fetch(:codes, {})
      @protocol = interpret_protocol_arg(args)
    end

    # Returns a Transmission representing the code identified by +key_sym+
    def call(key_sym)
      protocol.encode self[key_sym]
    end

    # Exports the codex to a YAML representation and returns that string
    def to_yaml
      Psych.dump(export_yaml)
    end

    # Takes in an optional override +fpath+ and saves a copy of the yaml version
    def save_file(fpath = nil)
      File.open(fpath || @path, 'w+') { |f| f << to_yaml }
    end

    private

    # Runs +parse_yaml+ on the file at #path and sets instance variables
    def load_from_existing_yaml(yaml = nil)
      yml = parse_yaml(yaml)

      @remote_name = yml[:remote_name]
      @path ||= "./#{@remote_name}_codex.yaml"
      @protocol = yml[:protocol].new(yml[:protocol_options])
      @codes = yml[:codes]
    end

    # Returns a simple hash to write out to file
    def export_yaml
      file = {}

      file[:metadata] = {}

      file[:metadata][:remote_name] = remote_name
      file[:metadata][:protocol] = protocol.to_sym
      file[:metadata][:protocol_options] = protocol.export_options

      file[:codes] = codes

      file
    end

    # Takes in the read +yaml+ and extracts relevant data out of it
    def parse_yaml(yaml)
      {
        remote_name: yaml[:metadata][:remote_name],
        protocol: LilBlaster::Protocol[yaml[:metadata][:protocol]],
        protocol_options: yaml[:metadata][:protocol_options],
        codes: yaml[:codes]
      }
    end

    # Takes in the +args+ and decides how to construct the protocol object
    def interpret_protocol_arg(args)
      proto = args.fetch(:protocol, nil)
      proto_opts = args.fetch(:protocol_options, {})

      if proto.is_a?(Symbol)
        Protocol[proto].new(proto_opts)
      elsif proto.is_a?(Class) && Protocol::BaseProtocol.descendants.include?(proto)
        proto.new(proto_opts)
      elsif Protocol::BaseProtocol.descendants.include?(proto.class)
        proto
      end
    end

    class << self
      private

      # Scan +files+ for valid codexes and load them
      def standard_codexes(files)
        files.select { |filename| filename =~ /_codex\.ya?ml$/i }
             .map { |fpath| self.load(fpath) }
      end

      # Scan +files+ for valid lirc confs and loads them as Codexes
      def lirc_confs(files)
        files.select { |filename| filename =~ /\.lircd\.conf$/i }
             .map { |fpath| LircConfReader.call(File.read(fpath)) }
      end
    end
  end
end
