require_relative '../command'

module LilBlaster
  module Commands #:nodoc:
    # Easy interface for sending pre-defined codes
    class SendCode < LilBlaster::Command
      def execute(_input: $stdin, _output: $stdout)
        if @options[:raw]
          # LilBlaster::Blaster.transmit(resolved_codex.protocol.encode(numberize_raw_value))
          puts pastel.green("Sent value #{@options[:raw]} using #{resolved_codex.remote_name}")
        else
          # LilBlaster::Blaster.send_code(resolved_symbol, resolved_codex)
          puts pastel.green("Sent code #{resolved_symbol} using #{resolved_codex.remote_name}")
        end
      end

      private

      def interactive_codex_choice(codexes = LilBlaster::Codex.autoload)
        choice = prompt.select('Select Codex: ', codexes.map(&:remote_name))
        codexes.find { |c| c.remote_name == choice }
      end

      def interactive_symbol_choice(symbs)
        prompt.select('Select a code to send: ', symbs)
      end

      def resolved_symbol
        return @resolved_symbol if @resolved_symbol

        @resolved_symbol = if @argv[:symbol]
                             @argv[:symbol].to_sym
                           elsif LilBlaster::ConfigFile[:default_code]
                             LilBlaster::ConfigFile[:default_code].to_sym
                           elsif @options[:interactive]
                             interactive_symbol_choice(resolved_codex.keys)
                           elsif @options[:raw]
                             nil
                           else
                             abort pastel.red('No symbol or raw value provided')
                           end
      end

      def resolved_codex
        return @resolved_codex if @resolved_codex

        @resolved_codex = if @options[:codex]
                            LilBlaster::Codex.load(@options[:codex])
                          elsif @argv[:codex_name]
                            LilBlaster::Codex.autoload.find do |codex|
                              codex.remote_name.downcase == @argv[:codex_name].downcase
                            end
                          elsif LilBlaster::ConfigFile[:default_codex]
                            LilBlaster::Codex.autoload.find do |codex|
                              codex.remote_name.downcase == LilBlaster::ConfigFile[:default_codex]
                            end
                          elsif @options[:raw]
                            interactive_codex_choice
                          else
                            codex_responding_to(resolved_symbol)
                          end
      end

      def codex_responding_to(sym)
        fc = LilBlaster::Codex.autoload.find_all do |codex|
          codex.key?(sym)
        end

        if fc.one?
          fc.first
        elsif fc.empty?
          abort pastel.red("No codex found which can respond to #{resolved_symbol}")
        else
          @options[:interactive] ? interactive_codex_choice(fc) : fc.first
        end
      end

      def numberize_raw_value
        Integer(@options[:raw])
      end
    end
  end
end
