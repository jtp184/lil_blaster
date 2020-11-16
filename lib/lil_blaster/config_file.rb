require 'tty-config'

module LilBlaster
  # Provides an interface for the config file to be accessed
  class ConfigFile
    # The filename to use for the config
    FILENAME = 'lil_blaster_config'.freeze

    class << self
      # Exposes the underlying TTY::Config object, loading from disk when posisble
      def config
        return @config unless @config.nil?

        @config = TTY::Config.new
        @config.filename = FILENAME

        config_paths.each { |pth| @config.append_path(pth) }
        safe_read_config
        pinout_config

        @config
      end

      # Reads the config in again
      def reload
        safe_read_config
      end

      # Syntax sugar for fetching the +value+
      def [](value)
        config.fetch(value)
      end

      # Syntax sugar for setting the +value+ of +key+
      def []=(key, value)
        config.set(key, value: value) && pinout_config
      end

      # Allows +mtd+ forwarding to #config or its hash representation
      def method_missing(mtd, *args, &blk)
        cf = config.method(mtd) if config.respond_to?(mtd)
        hs = config.to_h.method(mtd) if config.to_h.respond_to?(mtd)

        super unless cf || hs

        (cf || hs).call(*args, &blk)
      end

      # Politely respond when +mtd+ is missing
      def respond_to_missing?(mtd, *args)
        config.respond_to?(mtd) || config.to_h.respond_to?(mtd) || super
      end

      # Searches the #config_paths and returns the first found instance of this file, or nil
      def path
        files = config.location_paths.map do |pth|
          next [] unless Dir.exist?(pth)

          Dir.entries(pth)
             .reject { |x| x =~ /^\.{1..2}$/ }
             .map { |x| [pth, x].join('/') }
        end

        files.flatten.find { |x| x =~ /#{FILENAME}/ }
      end

      # Takes an optional override +path+ and calls #write on the config
      def save(path = nil)
        arg = path ? [path, { force: true }] : [{ force: true }]
        config.write(*arg)
      end

      private

      # If the reader or transmitter pin options are present, override the module variable
      def pinout_config
        tp = @config.fetch(:transmitter_pin)
        rp = @config.fetch(:reader_pin)

        return unless tp || rp

        LilBlaster.transmitter_pin = Integer(tp) if tp
        LilBlaster.reader_pin = Integer(rp) if rp
      end

      # The paths to search for a file. First the working directory, then the dotfiles, then home
      def config_paths
        [Dir.pwd, Dir.home + '/.config/lil_blaster', Dir.home]
      end

      # Defaults for the config
      def default_config_options
        {
          codexes_dir: os_based_dir('codexes')
        }.transform_keys(&:to_s).freeze
      end

      # Returns a default directory based on operating system
      def os_based_dir(join_path = nil)
        pth = case LilBlaster.host_os
              when :raspberrypi
                Dir.home
              when :windows, :mac
                Dir.home + '/lil_blaster'
              when :linux
                Dir.home + '/.config/lil_blaster'
              end

        return pth unless join_path

        Pathname.new(pth).join(join_path).to_s
      end

      # Reads from the config, rescuing a readerror by merging the default options
      def safe_read_config
        @config.read
      rescue TTY::Config::ReadError
        @config.merge(default_config_options)
      end
    end
  end
end
