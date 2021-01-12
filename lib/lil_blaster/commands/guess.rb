require_relative '../command'

module LilBlaster
  module Commands #:nodoc:
    # Guesses a remote codex from those within the LIRC dump
    class Guess < LilBlaster::Command
      # Primary command runner
      def execute(_input: $stdin, _output: $stdout)
        srch = capture_sample
        guesses = search_dump(srch)

        unless guesses.any?
          puts pastel.red('No matches')
          abort
        end

        choose_result(guesses)
      end

      private

      # Prompts to choose one of the +guesses+ and save it to the codexes directory
      def choose_result(guesses)
        choice = prompt.select('Possible matches:', guesses.map(&:remote_name))
        codex = lirc_remotes_dump.find { |r| r.remote_name == choice }

        fpath = LilBlaster::ConfigFile[:codexes_dir] + "/#{codex.remote_name}_codex.yml"
        codex.save_file(fpath)
        puts "Saved to #{pastel.yellow(fpath)}"
      end

      # Searches the lirc dumps using +search_params+
      def search_dump(search_params)
        lirc_remotes_dump.select do |codex|
          next unless search_params[:protocol].all? do |key, val|
            codex.protocol.respond_to?(key) && codex.protocol.send(key) == val
          end

          next unless search_params[:codes].all? do |val|
            codex.value?(val)
          end

          true
        end
      end

      # Captures some remote samples
      def capture_sample
        puts 'Ready to capture protocol information'
        puts 'Please press several different buttons on your remote'

        transmissions = LilBlaster::Reader.record(seconds: 10, first: 30)
        proto = LilBlaster::Protocol[LilBlaster::Protocol.identify(transmissions.first)]

        puts pastel.green('Done!')

        {
          protocol: {
            system_data: proto.system_data(transmissions.first)
          },
          codes: codes.uniq { |c| proto.bytestring_for(c) }.map { |c| proto.command_data(c) }
        }
      end

      # Unmarshals the lirc_remotes_dump from the vendor folder
      def lirc_remotes_dump
        @lirc_remotes_dump ||= Marshal.load(File.read(LilBlaster.vendor_path('lirc_remotes_dump')))
      end
    end
  end
end
