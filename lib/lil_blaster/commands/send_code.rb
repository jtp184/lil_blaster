require_relative '../command'

module LilBlaster
  module Commands #:nodoc:
    # Easy interface for sending pre-defined codes
    class SendCode < LilBlaster::Command
      def execute(_input: $stdin, _output: $stdout)
      end

      private

      def interactive_codex_choice
      end

      def interactive_symbol_choice
      end

      def resolved_symbol
      end

      def resolved_codex
      end
    end
  end
end
