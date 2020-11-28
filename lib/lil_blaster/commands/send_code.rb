require_relative '../command'

module LilBlaster
  module Commands #:nodoc:
    # Easy interface for sending pre-defined codes
    class SendCode < LilBlaster::Command
      # Primary command runner
      def execute(_input: $stdin, _output: $stdout)
        multi = @options[:times] || 1

        if @options[:raw]
          LilBlaster::Blaster.transmit(resolved_codex.protocol.encode(numberize_raw_value))
          puts pastel.green("Sent value #{@options[:raw]} using #{resolved_codex.remote_name}")
        elsif @argv[:symbols].empty?
          symbs = if @options[:interactive]
                    interactive_symbol_choice(resolved_codex.keys)
                  elsif LilBlaster::ConfigFile[:default_code]
                    [LilBlaster::ConfigFile[:default_code].to_sym]
                  else
                    abort pastel.red('No symbol provided')
                  end

          symbs.each { |sy| send_code_and_report(sy, multi) }
        else
          collect_symbols.each { |sym| send_code_and_report(sym, multi) }
        end
      end

      private

      # Tries to find a codex that can respond to +sym+, and sends that code if found.
      # Prints a report if successful, a failure message if not
      def send_code_and_report(sym, multi)
        dex = resolved_codex || codex_responding_to(sym)

        if dex
          LilBlaster::Blaster.send_code(sym, codex: dex, repetitions: multi)
          puts format(rept_str, sym: sym, rem: dex.remote_name)
        else
          puts pastel.red("No codex found which can respond to #{sym}")
        end
      end

      # Prompts for a choice between +codexes+
      def interactive_codex_choice(codexes = LilBlaster::Codex.autoload)
        abort pastel.red('No codexes exist') if codexes.empty?

        choice = prompt.select('Select Codex: ', codexes.map(&:remote_name))
        codexes.find { |c| c.remote_name == choice }
      end

      # A multi_select for the +symbs+
      def interactive_symbol_choice(symbs)
        prompt.multi_select('Select codes to send: ', symbs)
      end

      # Maps the cli args passed in as args to symbols
      def collect_symbols
        @collect_symbols ||= @argv[:symbols].map(&:to_sym)
      end

      # Memoizes a codex based on the codex flag
      def resolved_codex
        @resolved_codex ||= if @options[:codex] && File.exist?(@options[:codex])
                              LilBlaster::Codex.load(@options[:codex])
                            elsif @options[:codex]
                              LilBlaster::Codex.autoload.find do |codex|
                                codex.remote_name.downcase == @options[:codex].downcase
                              end
                            elsif @options[:raw] && @options[:interactive]
                              interactive_codex_choice
                            elsif LilBlaster::ConfigFile[:default_codex]
                              LilBlaster::Codex.autoload.find do |codex|
                                [
                                  codex.remote_name,
                                  LilBlaster::ConfigFile[:default_codex] || ''
                                ].map(&:downcase).reduce(&:==)
                              end
                            elsif @options[:interactive]
                              interactive_codex_choice
                            end
      end

      # Finds a codex which responds to +sym+, nil if none found
      def codex_responding_to(sym)
        fc = LilBlaster::Codex.autoload.find_all do |codex|
          codex.key?(sym)
        end

        return nil if fc.empty?
        return fc.first if fc.one?

        if @options[:interactive]
          interactive_codex_choice(fc)
        else
          default = fc.find do |codex|
            codex.remote_name.downcase == LilBlaster::ConfigFile[:default_codex].downcase
          end

          default || fc.first
        end
      end

      # Convert the value passed in as the raw flag to an integer
      def numberize_raw_value
        Integer(@options[:raw])
      end

      # Memoizes a report string
      def rept_str
        return @rept_str if @rept_str

        @rept_str = +pastel.green('Sent code ')
        @rept_str << '%<sym>s'
        @rept_str << pastel.green(' using ')
        @rept_str << '%<rem>s'.freeze
      end
    end
  end
end
