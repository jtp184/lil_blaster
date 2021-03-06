# frozen_string_literal: true

require 'forwardable'
require 'strings-case'

module LilBlaster
  # A Command runner under the CLI
  class Command
    extend Forwardable

    def_delegators :command, :run

    # Default initializer to provide options as an ivar
    def initialize(options = {}, argv = {})
      @options = options
      @argv = argv
    end

    # Execute this command
    #
    # @api public
    def execute(*)
      raise(
        NotImplementedError,
        "#{self.class}##{__method__} must be implemented"
      )
    end

    # The external commands runner
    #
    # @see http://www.rubydoc.info/gems/tty-command
    #
    # @api public
    def command(**options)
      require 'tty-command'
      TTY::Command.new(options)
    end

    # The cursor movement
    #
    # @see http://www.rubydoc.info/gems/tty-cursor
    #
    # @api public
    def cursor
      require 'tty-cursor'
      TTY::Cursor
    end

    # Open a file or text in the user's preferred editor
    #
    # @see http://www.rubydoc.info/gems/tty-editor
    #
    # @api public
    def editor
      require 'tty-editor'
      TTY::Editor
    end

    # File manipulation utility methods
    #
    # @see http://www.rubydoc.info/gems/tty-file
    #
    # @api public
    def generator
      require 'tty-file'
      TTY::File
    end

    # Terminal output paging
    #
    # @see http://www.rubydoc.info/gems/tty-pager
    #
    # @api public

    def pager(**options)
      require 'tty-pager'
      TTY::Pager.new(options)
    end

    # Colorization for text
    #
    # @see http://www.rubydoc.info/gems/pastel
    #
    # @api public
    def pastel(**options)
      require 'pastel'
      Pastel.new(options)
    end

    # Terminal platform and OS properties
    #
    # @see http://www.rubydoc.info/gems/tty-pager
    #
    # @api public
    def platform
      require 'tty-platform'
      TTY::Platform.new
    end

    # The interactive prompt
    #
    # @see http://www.rubydoc.info/gems/tty-prompt
    #
    # @api public
    def prompt(**options)
      require 'tty-prompt'
      TTY::Prompt.new(options.merge(interrupt: -> { puts; puts; puts "Canceled".magenta; abort }))
    end

    # Get terminal screen properties
    #
    # @see http://www.rubydoc.info/gems/tty-screen
    #
    # @api public
    def screen
      require 'tty-screen'
      TTY::Screen
    end

    # Animated spinner for non deterministic tasks
    #
    # @see http://www.rubydoc.info/gems/tty-spinner
    #
    # @api public
    def spinner(message, opts = {})
      require 'tty-spinner'
      TTY::Spinner.new(
        message,
        opts.merge(
          success_mark: '✅',
          error_mark: '❗️',
          frames: '🕒🕓🕔🕕🕖🕗🕘🕙🕚🕛🕐🕑',
          interval: 24
        )
      )
    end

    # The unix which utility
    #
    # @see http://www.rubydoc.info/gems/tty-which
    #
    # @api public
    def which(*args)
      require 'tty-which'
      TTY::Which.which(*args)
    end

    # Check if executable exists
    #
    # @see http://www.rubydoc.info/gems/tty-which
    #
    # @api public
    def exec_exist?(*args)
      require 'tty-which'
      TTY::Which.exist?(*args)
    end
  end
end
