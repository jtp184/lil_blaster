require 'strings-case'
require 'lil_blaster/version'
require 'lil_blaster/config_file'
require 'lil_blaster/gpio/gpio'
require 'lil_blaster/noise_reducer'
require 'lil_blaster/protocol/protocol'
require 'lil_blaster/protocol/manchester'
require 'lil_blaster/protocol/rcmm'
require 'lil_blaster/protocol/morse'
require 'lil_blaster/transmission'
require 'lil_blaster/codex'
require 'lil_blaster/lirc_conf_reader'
require 'lil_blaster/buttons'
require 'lil_blaster/blaster'
require 'lil_blaster/reader'

# Ruby gem for interacting with Infrared transmissions on the Raspberry Pi
module LilBlaster
  class << self
    # Allows changing which pin is used to transmit on, defaults to 17
    attr_writer :transmitter_pin
    # Allows changing which pin is used to read on, defaults to 18
    attr_writer :reader_pin
    # Allows changing which pins are used to read the buttons, defaults to [27, 22]
    attr_writer :button_pins

    # Defaults to 17
    def transmitter_pin
      @transmitter_pin ||= 17
    end

    # Defaults to 18
    def reader_pin
      @reader_pin ||= 18
    end

    # Defaults to [27, 22] in keeping with the numbering on the faceplate
    def button_pins
      @button_pins ||= [27, 22]
    end

    # Examines the RUBY_PLATFORM constant to determine what OS we are running on.
    # Returns one of :windows, :mac, :linux, or :raspberrypi
    def host_os
      case RUBY_PLATFORM
      when /cygwin|mswin|mingw|bccwin|wince|emx/
        :windows
      when /darwin/
        :mac
      when /linux/
        pi = File.read('/proc/cpuinfo') =~ /Raspberry Pi/
        pi ? :raspberrypi : :linux
      end
    end

    # Returns the path to the vendor directory for this gem, to access non-ruby
    # assets like the lirc_remotes_dump.
    # If +paths+ are appended, joins them to the base with '/'
    def vendor_path(*paths)
      @vendor_path ||= String.new(locate_gem_folder).tap do |str|
        str << '/gems'
        str << "/lil_blaster-#{LilBlaster::VERSION}"
        str << '/vendor'
      end

      return @vendor_path if paths.empty?

      [String.new(@vendor_path)].concat(paths).join('/')
    end

    # Returns a blob for use with PiMaker
    def pi_maker_recipe
      {
        boot_config_options: {
          config: { 'dtparam=spi': 'on' }
        },
        initial_setup_options: {
          ruby_version: '2.7.5',
          github_repos: {
            'jtp184/lil_blaster': [
              'cd ~/repos/lil_blaster && bundle',
              'cd ~/repos/lil_blaster && rake install'
            ]
          },
          gems: %w[
            bundler
            rake
            colorize
            pigpio
          ],
          shell: ['touch ~/.hushlogin'],
          raspi_config: { do_expand_rootfs: nil },
          bashrc: ['if ! [ -e /var/run/pigpiod.pid ]; then sudo pigpiod start; fi']
        }
      }
    end

    private

    # Figures out where to look for gems using Gem.path
    def locate_gem_folder
      looks, _nopes = Gem.path.partition { |pth| Dir.exist?(pth) }

      has_them, _doesnt = looks.partition do |pth|
        Dir.entries(pth).include?('gems')
      end

      has_them.first
    end
  end
end
