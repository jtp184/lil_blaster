module LilBlaster
  # Provides an interface for the config file to be accessed
  class ConfigFile
    FILENAME = 'lil_blaster_config'.freeze

    class << self
      def config
        return @config if @config

        @config = TTY::Config.new
        @config.filename = FILENAME

        config_paths.each { |pth| @config.append_path(pth) }

        begin
          @config.read
        rescue TTY::Config::ReadError
          @config.merge(default_config_options)
        end

        pinout_config

        @config
      end

      def [](val)
        config.fetch(val)
      end

      def []=(key, val)
        config.set(key, value: val)
      end

      def method_missing(mtd, *args, &blk)
        cf = config.method(mtd) if config.respond_to?(mtd)
        hs = config.to_h.method(mtd) if config.to_h.respond_to?(mtd)

        super unless cf || hs

        (cf || hs).call(*args, &blk)
      end

      def respond_to_missing?(mtd, *args)
        config.respond_to?(mtd) || config.to_h.respond_to?(mtd) || super
      end

      def to_h
        config.to_h
      end

      def path
        files = config_paths.map do |pth|
          next [] unless Dir.exist?(pth)

          Dir.entries(pth)
          .reject { |x| x =~ /^\.{1..2}$/ }
          .map { |x| [pth, x].join('/') }
        end

        files.flatten.find { |x| x =~ /#{FILENAME}/ }
      end

      def exist?
        !!path
      end

      def save(path = nil)
        arg = path ? [path, { force: true }] : [{ force: true }]
        config.write(*arg)
      end

      private

      def pinout_config
        tp = config.fetch(:transmitter_pin)
        rp = config.fetch(:reader_pin)

        return unless tp || rp

        LilBlaster.transmitter_pin = Integer(tp) if tp
        LilBlaster.reader_pin = Integer(rp) if rp
      end

      def config_paths
        [Dir.pwd, Dir.home + '/.config/lil_blaster', Dir.home]
      end

      def default_config_options
        {
          remotes_folder: Dir.home + '/.config/lil_blaster/remotes/',
          default_remote: nil
        }
      end
    end
  end
end
