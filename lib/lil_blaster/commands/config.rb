require_relative '../command'

module LilBlaster
  module Commands #:nodoc:
    # Initial tool setup
    class Config < LilBlaster::Command
      def execute(input: $stdin, output: $stdout)
        config_file.write(force: true) unless file_exist?

        if @options.key?(:interactive)
          interactive
        elsif @options.key?(:get)
          puts config_file.fetch(@options[:get])
        elsif @options.key?(:set)
          set_config_file_option
          puts @options[:set].join(' => ')
        end
      end

      def interactive
        config_file.to_h.each do |key, value|
          resp = prompt.ask("#{Strings::Case.titlecase key}: ", default: value)
          config_file.set(key, value: resp)
        end

        config_file.write(force: true)
      end

      private

      def set_config_file_option
        config_file.set(
          @options[:set][0],
          value: @options[:set][1]
        )

        config_file.write(force: true)
      end

      def file_exist?
        LilBlaster::CLI.config_file_exist?
      end

      def config_file
        LilBlaster::CLI.config_file
      end
    end
  end
end
