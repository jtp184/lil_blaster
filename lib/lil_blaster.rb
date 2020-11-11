require 'lil_blaster/version'
require 'lil_blaster/gpio/gpio'
require 'lil_blaster/protocol/protocol'
require 'lil_blaster/protocol/manchester'
require 'lil_blaster/protocol/morse'
require 'lil_blaster/transmission'
require 'lil_blaster/codex'
require 'lil_blaster/blaster'
require 'lil_blaster/reader'

# Ruby gem for interacting with Infrared transmissions on the Raspberry Pi
module LilBlaster
  class << self
    # Allows changing which pin is used to transmit on, defaults to 17
    attr_writer :transmitter_pin
    # Allows changing which pin is used to read on, defaults to 18
    attr_writer :reader_pin

    # Defaults to 17
    def transmitter_pin
      @transmitter_pin ||= 17
    end

    # Defaults to 18
    def reader_pin
      @reader_pin ||= 18
    end
  end
end
