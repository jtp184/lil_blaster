require 'lil_blaster/version'
require 'lil_blaster/gpio/gpio'
require 'lil_blaster/transmission'
require 'lil_blaster/blaster'

# Ruby gem for interacting with Infrared transmissions on the Raspberry Pi
module LilBlaster
  class << self
    # Allows changing which pin is used to transmit on, defaults to 17
    attr_writer :transmitter_pin

    # Defaults to 17
    def transmitter_pin
      @transmitter_pin ||= 17
    end
  end
end
