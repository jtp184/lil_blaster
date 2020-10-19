require 'ostruct'

module LilBlaster
  # Handles the low level interfacing with the Pi
  module GPIO
    class << self
      def connection
        @connection ||= driver.new
      end

      def driver
        if pigpio_defined?
          Pigpio
        else
          warn 'Pigpio is not defined, please require it.'
          nil
        end
      end

      private

      def pigpio_defined?
        defined?(Pigpio)
      end
    end
  end
end
