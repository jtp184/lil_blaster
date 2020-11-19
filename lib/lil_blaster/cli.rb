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
    # Error raised by this runner
    Error = Class.new(StandardError)

    # Returns proper exit code
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

    desc 'config', 'Initialize, set, and get configuration options'
    method_option :interactive, aliases: '-i', type: :boolean, desc: 'Edit settings with an interactive prompt'
    method_option :set, aliases: '-s', type: :array, desc: 'Set a configuration value'
    method_option :get, aliases: '-g', type: :string, desc: 'Get the current value of a config setting'
    method_option :unset, aliases: '-u', type: :string, desc: 'Unset a configuration value'

    # Initialize, set, and get configuration options
    def config
      if options[:help]
        invoke :help, [:config]
      else
        require_relative 'commands/config'

        LilBlaster::Commands::Config.new(options).execute
      end
    end
  end
end
