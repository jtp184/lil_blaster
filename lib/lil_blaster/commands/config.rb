require_relative '../command'

module LilBlaster
  module Commands #:nodoc:
    # Initial tool setup
    class Config < LilBlaster::Command
      def execute(_input: $stdin, _output: $stdout)
        if @options.empty?
          unless ConfigFile.exist?
            ConfigFile.save
            puts 'Saved new config file'
          end

          puts "PATH: #{ConfigFile.path}"
        elsif @options.key?(:interactive)
          ConfigFile.each do |key, value|
            resp = prompt.ask("#{Strings::Case.titlecase key}: ", default: value)
            ConfigFile[key] = resp
          end

          ConfigFile.save
        elsif @options.key?(:get) && %w[get all].include?(@options[:get])
          ConfigFile.each do |tuple|
            puts tuple.join(' => ')
          end
        elsif @options.key?(:get)
          resp = ConfigFile[@options[:get]]

          puts resp
        elsif @options.key?(:set)
          ConfigFile[@options[:set][0]] = @options[:set][1]

          puts @options[:set].join(' => ')

          ConfigFile.save
        end
      end
    end
  end
end
