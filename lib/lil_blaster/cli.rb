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
        ],
        [
          :set,
          { aliases: '-s', type: :array, desc: 'Set a configuration value' }
        ],
        [
          :get,
          { aliases: '-g', type: :string, desc: 'Get the current value of a config setting' }
        ]
      ]
    )
  end
end
