# frozen_string_literal: true

require 'thor'
require 'tty-config'
require 'strings-case'

module LilBlaster
  # Handle the application command line parsing
  # and the dispatch to various command objects
  #
  # @api public
  class CLI < Thor
    class << self
      def def_command(args = {})
        cmd = args.fetch(:cmd)

        sym = cmd.to_sym
        str = cmd.to_str
        cons = Strings::Case.pascalcase(str).to_sym

        desc str, args.fetch(:desc)

        args.fetch(:method_options, []).each do |mop|
          method_option(*mop)
        end

        define_method(sym) do
          if options[:help]
            invoke :help, [str]
          else
            require_relative "commands/#{str}"

            LilBlaster::Commands.const_get(cons)
                                .new(options)
                                .execute
          end
        end
      end

      def config_file
        return @config_file if @config_file

        @config_file = TTY::Config.new
        @config_file.filename = 'lil_blaster_config'

        config_paths.each { |pth| @config_file.append_path(pth) }

        begin
          @config_file.read
        rescue TTY::Config::ReadError
          @config_file.merge(default_config_options)
        end

        @config_file
      end

      def config_file_path
        files = config_paths.map do |pth|
          next [] unless Dir.exist?(pth)

          Dir.entries(pth)
             .reject { |x| x =~ /^\.{1..2}$/ }
             .map { |x| [pth, x].join('/') }
        end

        files.flatten.find { |x| x =~ /lil_blaster_config/ }
      end

      def config_file_exist?
        !!config_file_path
      end

      private

      def config_paths
        [Dir.pwd, Dir.home + '/.config/lil_blaster', Dir.home]
      end

      def default_config_options
        { remotes_folder: Dir.home + '/.config/lil_blaster/remotes/' }
      end
    end

    # Error raised by this runner
    Error = Class.new(StandardError)

    def self.exit_on_failure?
      true
    end

    #### COMMANDS ####

    desc 'version', 'lil_blaster version'

    # Returns gem version
    def version
      require_relative 'version'
      puts "v#{LilBlaster::VERSION}"
    end

    map %w[--version -v] => :version

    def_command(
      cmd: 'config',
      desc: 'Initialize, set, and get configuration options',
      method_options: [
        [
          :interactive,
          { aliases: '-i', type: :boolean, desc: 'Edit settings with an interactive prompt' }
        ]
      ]
    )
  end
end
