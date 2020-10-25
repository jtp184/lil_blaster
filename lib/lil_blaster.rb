require 'lil_blaster/version'
require 'lil_blaster/gpio'
require 'lil_blaster/blaster'

# Ruby gem for interacting with Infrared transmissions on the Raspberry Pi
module LilBlaster
  attr_writer :transmitter_pin

  # Defaults to 17
  def transmitter_pin
    @transmitter_pin ||= 17
  end
end
