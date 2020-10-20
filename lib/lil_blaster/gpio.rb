require 'ostruct'

module LilBlaster
  # Handles the low level interfacing with the Pi
  module GPIO
    class << self
      # Exposes the waveform creation and execution interface
      def wavetuner
        connection.wave
      end

      # Takes in the +pin_id+ and returns a gpio pin class
      def gpio_pin(pin_id)
        connection.gpio(pin_id)
      end

      # Memoizes and returns the hardware interface
      def connection
        @connection ||= driver.new
      end

      # Determines what to use as the driver, based on #pigpio_defined?
      def driver
        if pigpio_defined?
          Pigpio
        else
          warn 'Pigpio is not defined, please require it.'
          nil
        end
      end

      private

      # Checks if we have Pigpio defined for use
      def pigpio_defined?
        defined?(Pigpio)
      end
    end
  end
end
