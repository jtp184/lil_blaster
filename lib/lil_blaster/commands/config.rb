require_relative '../command'

module LilBlaster
  module Commands #:nodoc:
    # Initial tool setup
    class Config < LilBlaster::Command
      def execute(input: $stdin, output: $stdout)
        puts @options
      end
    end
  end
end
