require_relative '../command'

module LilBlaster
  module Commands #:nodoc:
    # Learning new remotes and codes
    class Learn < LilBlaster::Command
      # Primary command runner
      def execute(_input: $stdin, _output: $stdout)
        if current_codex.protocol.nil?
          learn_protocol && sleep(1)
          learn_repeats && sleep(1)
          puts pastel.green('Protocol identified')
        end

        current_keys.each do |key|
          learn_new_symbol(key)
          puts
        end

        current_codex.save_file
        puts "Codex saved to #{pastel.yellow current_codex.path}"
      end

      # Identifies the protocol from a sampling of buttons
      def learn_protocol
        puts 'Ready to capture protocol information'
        puts 'Please single-press 5-10 random buttons on the remote now'

        proto_data = LilBlaster::Reader.record(seconds: -1, first: 10)

        puts pastel.green('Done!')

        smoothing = LilBlaster::NoiseReducer.replacement_matrix(proto_data.map(&:data).flatten)
        current_codex.protocol = LilBlaster::Protocol.identify!(proto_data.first % smoothing)[0]
      end

      # Identifies any present repeat code from a held button
      def learn_repeats
        puts 'Please press and hold one button on the remote now'

        rpt_data = LilBlaster::Reader.record(seconds: -1, first: 4)

        puts pastel.green('Done!')

        id = identify_code(rpt_data)[:repeat]
        current_codex.protocol.pulse_values[:repeat] = id if id
      end

      # Given a +sym+ it captures a transmission and decodes it, then adds to the current codex
      def learn_new_symbol(sym)
        sleep 2
        puts
        puts "Ready to capture `#{pastel.yellow(sym.to_s)}`"
        puts 'Please press and hold the key'

        burst = LilBlaster::Reader.record(first: 4)

        puts pastel.cyan('Release the key now')

        id = identify_code(burst)[:command]
        pr = current_codex.value?(id)

        if current_codex.key?(sym) && !@options[:overwrite]
          puts pastel.red('Key already present, use --overwrite to replace it')
        elsif pr
          raise IndexError
        else
          current_codex.codes[sym] = id
        end
      rescue IndexError
        puts(pastel.red('Duplicate key detected, retrying'))
        retry
      end

      private

      # Takes in an array of transmissions +burst+, and extracts a protocol, command, and repeat
      def identify_code(burst)
        if burst.any? { |t| t.count == 4 }
          data = burst.max_by(&:count)
          rpt = burst.min_by(&:count).tuples.first

          proto, code = LilBlaster::Protocol.identify!(data)
        else
          proto, code = LilBlaster::Protocol.identify!(burst.first)
          rpt = nil
        end

        { protocol: proto, command: code, repeat: rpt }
      end

      # Memoizes keys based on either the flags, interactive pick, or default key bundle
      def current_keys
        @current_keys ||= if @options[:keys]
                            @options[:keys].map(&:to_sym)
                          elsif @options[:interactive]
                            pick_key_bundle_interactive
                          else
                            key_bundles[:minimal]
                          end
      end

      # Finds the codex specified by the flag, creating it if necessary
      def current_codex
        return @current_codex if @current_codex
        return @current_codex ||= pick_codex_interactive if @options[:interactive]
        raise ArgumentError, 'No Codex provided' unless @options[:codex]

        srch = @options[:codex]

        matched = LilBlaster::Codex.autoload.find do |cdx|
          cdx.remote_name.downcase =~ /^#{srch}$/
        end

        @current_codex = if matched.nil?
                           LilBlaster::Codex.new(
                             remote_name: srch,
                             path: LilBlaster::ConfigFile[:codexes_dir] + "/#{srch}_codex.yml"
                           )
                         else
                           matched
                         end
      end

      # Defines and memoizes groups of keys to present as options
      def key_bundles
        @key_bundles ||= {
          minimal: %i[ok],
          basic: %i[power up down left right],
          audio: %i[volume_up volume_down mute],
          seeking: %i[pause fast_forward rewind],
          numbers: %i[one two three four five six seven eight nine zero]
        }
      end

      # Presents a prompt to choose which bundles to use
      def pick_key_bundle_interactive
        bundles = key_bundles.map { |k, v| "#{k}: (#{v.join(', ')})" }
        chosen = prompt.multi_select('Choose keys to learn: ', bundles)

        chosen.map { |x| x.split(':')[0].to_sym }
              .map { |y| key_bundles[y] }
              .reduce(&:+)
      end

      # Present a prompt to select the codex
      def pick_codex_interactive
        existing = LilBlaster::Codex.autoload

        return new_codex_interactive if existing.empty?

        choices = existing.map(&:remote_name) << pastel.yellow('New Codex')
        chosen = prompt.select('Choose codex to add to: ', choices)

        if chosen =~ /New Codex/
          new_codex_interactive
        else
          LilBlaster::Codex.autoload.find { |c| c.remote_name == chosen }
        end
      end

      # Prompt for a name for a new codex, instantiate and return
      def new_codex_interactive
        rn = prompt.ask('New Codex name: ').downcase

        LilBlaster::Codex.new(
          remote_name: rn,
          path: LilBlaster::ConfigFile[:codexes_dir] + "/#{rn}_codex.yml"
        )
      end
    end
  end
end
