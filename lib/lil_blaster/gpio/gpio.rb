require 'lil_blaster/gpio/pin'
require 'lil_blaster/gpio/wave'

module LilBlaster
  # Handles the low level interfacing with the Pi
  module GPIO
    class << self
      # Memoizes and returns the hardware interface
      def connection
        @connection ||= driver.new.tap(&:connect)
      end

      # Determines what to use as the driver, based on whether we have access to Pigpio.
      # Attempts to load it if possible, but not on non-pi hardware
      def driver
        if defined?(Pigpio)
          Pigpio
        elsif LilBlaster.host_os == :raspberrypi
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

      def pi_constants
        return @pi_constants if @pi_constants

        cons = driver.const_get(:Constant)
        @pi_constants = cons.constants.map { |c| [c, cons.const_get(c)] }.to_h
      end

      def gpio_success(value)
        return value unless value.positive?

        err_str = "Hardware driver error. The error was `#{pi_constants.key(value)}` (#{value})"

        raise IOError, err_str
      end
    end
  end
end
