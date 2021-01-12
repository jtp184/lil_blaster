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
    method_option :interactive, aliases: '-i', type: :boolean,
                                desc: 'Edit settings with an interactive prompt'
    method_option :set, aliases: '-s', type: :array,
                        desc: 'Set a configuration value'
    method_option :get, aliases: '-g', type: :string,
                        desc: 'Get the current value of a config setting'
    method_option :unset, aliases: '-u', type: :string,
                          desc: 'Unset a configuration value'

    # Initialize, set, and get configuration options
    def config
      if options[:help]
        invoke :help, [:config]
      else
        require_relative 'commands/config'

        LilBlaster::Commands::Config.new(options).execute
      end
    end

    desc 'send_code [SYMBOLS...]', 'Send a code from a codex'
    method_option :codex, aliases: '-c', type: :string,
                          desc: 'Pass a codex name or filepath for the codex'
    method_option :raw, aliases: '-r', type: :string,
                        desc: 'Provide a raw number value instead of a symbol'
    method_option :interactive, aliases: '-i', type: :boolean,
                                desc: 'Choose what to send interactively'
    method_option :times, aliases: '-t', type: :numeric,
                          desc: 'Send the provided symbols multiple times'

    # Sends the code defined by the +symbol+ in a +codex+
    def send_code(*symbols)
      if options[:help]
        invoke :help, [:send_code]
      else
        require_relative 'commands/send_code'

        LilBlaster::Commands::SendCode.new(options, { symbols: symbols }).execute
      end
    end

    desc 'learn', 'Learn a new remote or code and save it out'
    method_option :interactive, aliases: '-i', type: :boolean, desc: 'Interactively choose options'
    method_option :codex, aliases: '-c', type: :string, desc: 'Which codex to save to'
    method_option :keys, aliases: '-k', type: :array, desc: 'The codes to add to the codex'
    method_option :overwrite, aliases: '-o', type: :boolean, desc: 'Overwrite existant codes'

    # Learns new codes and codexes by example
    def learn
      if options[:help]
        invoke :help, [:learn]
      else
        require_relative 'commands/learn'

        LilBlaster::Commands::Learn.new(options).execute
      end
    end

    desc 'guess', 'Guesses the remote from the LIRC remotes dump'

    def guess
      if options[:help]
        invoke :help, [:send_code]
      else
        require_relative 'commands/guess'

        LilBlaster::Commands::Guess.new(options).execute
      end
    end
  end
end
