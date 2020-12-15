require_relative '../command'

module LilBlaster
  module Commands #:nodoc:
    # Learning new remotes and codes
    class Learn
      def execute(_input: $stdin, _output: $stdout)
      end

      private

      def current_codex
        return @current_codex if @current_codex

        srch = @options[:codex]

        matched = LilBlaster::Codex.autoload.find do |cdx|
          cdx.remote_name.downcase =~ /^#{srch}$/
        end

        @current_codex = matched || LilBlaster::Codex.new(remote_name: srch)
      end
    end
  end
end
