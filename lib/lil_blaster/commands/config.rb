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
          interactive_edit
        elsif @options.key?(:get) && %w[get all].include?(@options[:get])
          all_keys
        elsif @options.key?(:get)
          single_value
        elsif @options.key?(:set)
          set_value
        elsif @options.key?(:unset)
          unset_value
        end
      end

      private

      # For each key in the config, runs a prompt asking for a new value with old value as default
      def interactive_edit
        ConfigFile.each do |key, value|
          resp = prompt.ask("#{Strings::Case.titlecase key}: ", default: value)
          ConfigFile[key] = resp
        end

        ConfigFile.save
      end

      # Stylizes all the keys, then prints them out
      def all_keys
        ConfigFile.each do |key, val|
          str = [
            pastel.green(key),
            val.nil? ? pastel.black('nil') : val
          ].join(link_arrow)

          puts str
        end
      end

      # Prints a single key value
      def single_value
        resp = ConfigFile[@options[:get]]

        str = if resp.nil?
                pastel.black('nil')
              else
                pastel.green(resp)
              end

        puts str
      end

      # Sets a value using the first and second elements in the @options[:set] array
      def set_value
        ConfigFile[@options[:set][0]] = @options[:set][1]
        ConfigFile.save

        puts @options[:set].join(link_arrow)
      end

      # Deletes the keys from @options[:unset]
      def unset_value
        ConfigFile.delete(@options[:unset])
        puts [pastel.red(@options[:unset]), pastel.black('nil')].join(link_arrow)

        ConfigFile.save
      end

      # Returns a grey arrow
      def link_arrow
        pastel.black(' => ')
      end
    end
  end
end
