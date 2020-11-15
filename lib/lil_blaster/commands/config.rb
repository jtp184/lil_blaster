require_relative '../command'

module LilBlaster
  module Commands #:nodoc:
    # Initial tool setup
    class Config < LilBlaster::Command
      def execute(_input: $stdin, _output: $stdout)
        LilBlaster::ConfigFile.save unless LilBlaster::ConfigFile.exist?

        if @options.key?(:interactive)
          LilBlaster::ConfigFile.each do |key, value|
            resp = prompt.ask("#{Strings::Case.titlecase key}: ", default: value)
            LilBlaster::ConfigFile[key] = resp
          end
        elsif @options.key?(:get) && %w[get all].include?(@options[:get])
          LilBlaster::ConfigFile.each do |tuple|
            puts tuple.join(' => ')
          end
        elsif @options.key?(:get)
          resp = LilBlaster::ConfigFile[@options[:get]]

          puts resp
        elsif @options.key?(:set)
          LilBlaster::ConfigFile[@options[:set][0]] = @options[:set][1]

          puts @options[:set].join(' => ')
        end

        LilBlaster::ConfigFile.save unless @options.key?(:get)
      end
    end
  end
end
