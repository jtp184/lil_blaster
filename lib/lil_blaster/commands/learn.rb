require_relative '../command'
require 'pry'

module LilBlaster
  module Commands #:nodoc:
    # Learning new remotes and codes
    class Learn < LilBlaster::Command
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

      def learn_protocol
        puts 'Ready to capture protocol information'
        puts 'Please single-press 5-10 random buttons on the remote now'

        proto_data = LilBlaster::Reader.record(seconds: -1, first: 8)

        puts pastel.green('Done!')

        smoothing = LilBlaster::NoiseReducer.replacement_matrix(proto_data.map(&:data).flatten)
        current_codex.protocol = LilBlaster::Protocol.identify!(proto_data.first % smoothing)[0]
      end

      def learn_repeats
        puts 'Please press and hold one button on the remote now'

        rpt_data = LilBlaster::Reader.record(seconds: -1, first: 4)

        puts pastel.green('Done!')

        current_codex.protocol.pulse_values[:repeat] = identify_code(rpt_data)[:repeat]
      end

      def learn_new_symbol(sym)
        puts "Ready to capture `#{pastel.yellow(sym.to_s)}`"
        sleep 0.5
        puts 'Please press and hold the key'

        burst = LilBlaster::Reader.record(first: 4)

        puts pastel.green('Done!')

        current_codex.codes[sym] = convert_transmissions(burst)[:command]
      end

      private

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

      def current_keys
        @current_keys ||= if @options[:keys]
                            @options[:keys].map(&:to_sym)
                          elsif @options[:interactive]
                            pick_key_bundle_interactive
                          else
                            key_bundles[:minimal]
                          end
      end

      def current_codex
        return @current_codex if @current_codex
        raise ArgumentError, 'No Codex provided' unless @options[:codex]

        srch = @options[:codex]

        matched = LilBlaster::Codex.autoload.find do |cdx|
          cdx.remote_name.downcase =~ /^#{srch}$/
        end

        @current_codex = matched || LilBlaster::Codex.new(remote_name: srch)
      end

      def key_bundles
        @key_bundles ||= {
          minimal: %i[ok],
          basic: %i[power up down left right],
          audio: %i[volume_up volume_down mute],
          seeking: %i[pause fast_forward rewind]
        }
      end

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
