require 'lil_blaster/gpio/pin'
require 'lil_blaster/gpio/wave'

module LilBlaster
  # Handles the low level interfacing with the Pi
  module GPIO
    class << self
      # Takes in the +pin_id+ and returns a gpio pin class
      def gpio_pin(pin_id)
        connection.gpio(pin_id)
      end

      # Memoizes and returns the hardware interface
      def connection
        @connection ||= driver.new.tap(&:connect)
      end

      # Determines what to use as the driver, based on whether we have access to Pigpio.
      # Attempts to load it if possible, but not on non-pi hardware
      def driver
        if defined?(Pigpio)
          Pigpio
        elsif Gem.platforms.last.os == 'linux' && File.read('/proc/cpuinfo') =~ /Raspberry Pi/
          begin
            require 'pigpio'
            Pigpio
          rescue LoadError
            warn 'WARN: Pigpio is not defined, please require it.'
            nil
          end
        else
          warn 'WARN: Pigpio driver is not available on non Raspberry Pi hardware.'
          nil
        end
      end
    end
  end
end
