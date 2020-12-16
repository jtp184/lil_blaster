require_relative '../command'
require 'pry'

module LilBlaster
  module Commands #:nodoc:
    # Learning new remotes and codes
    class Learn < LilBlaster::Command
      # Primary command runner
      def execute(_input: $stdin, _output: $stdout)
        if current_codex.protocol.nil?
          learn_protocol
          sleep 1
          learn_repeats
          sleep 1
          puts pastel.green('Protocol identified')
        end

        current_keys.each do |key|
          learn_new_symbol(key)
          puts
        end

        current_codex.save_file
        puts "Codex saved to #{current_codex.path}"
      end

      # Identifies the protocol from a sampling of buttons
      def learn_protocol
        puts 'Ready to capture protocol information'
        puts 'Please single-press 5-10 random buttons on the remote now'

        proto_data = LilBlaster::Reader.record(seconds: -1, first: 8)

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
        puts "Ready to capture `#{pastel.yellow(sym.to_s)}`"
        puts 'Please press and hold the key'

        burst = LilBlaster::Reader.record(first: 4)

        puts pastel.yellow('Please release the key now')

        id = identify_code(burst)[:command]

        if current_codex.key?(sym) && !@options[:overwrite]
          puts pastel.red('Key already present, use --overwrite to replace it')
        elsif current_codex.value?(id)
          puts pastel.red('Duplicate key detected, retrying')
          retry
        else
          current_codex.codes[sym] = id
        end
      end

      private

      # Takes in an array of transmissions +burst+, and extracts a protocol, command, and repeat
      def identify_code(burst)
        u = burst.uniq(&:count)

        if u.one?
          proto, code = LilBlaster::Protocol.identify!(u.first)
          rpt = nil
        else
          data = u.max_by(&:count)
          rpt = u.min_by(&:count).tuples.first

          proto, code = LilBlaster::Protocol.identify!(data)
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
    end
  end
end
