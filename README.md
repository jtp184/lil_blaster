# LilBlaster

LilBlaster is a gem for interacting with IR Transmitters and Receivers on the Raspberry Pi. It includes functionality to send, receive, identify, and catalog transmissions, with a particular penchant for handling IR Remote control codes.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'lil_blaster', github: 'jtp184/lil_blaster'
```
You can also download and install it globally with

```bash
git clone https://github.com/jtp184/lil_blaster
cd lil_blaster
rake install
```

For help setting up your pi for use with this gem, check out the [RASPI_SETUP](https://github.com/jtp184/lil_blaster/blob/master/RASPI_SETUP.md) instructions

## Hardware

This gem was developed using a generically available [IR Expansion Board](http://raspberrypiwiki.com/Raspberry_Pi_IR_Control_Expansion_Board) on the Raspberry Pi 3+, and various remotes including the Samsung BN59-01006A.

## LIRC

## CLI

## Usage

### Documentation

All methods and classes are RDoc documented at https://jtp184.github.io/lil_blaster

### Transmissions

A `Transmission` wraps a collection of pulse timings, with methods to help analyze them

```ruby
data = [500, 1000, 600, 2000]

t1 = LilBlaster::Transmission.new(data: d)

# You can optionally specify a carrier wave frequency in kHz, 
# with 38.0 being the default
t2 = LilBlaster::Transmission.new(data: d, carrier_wave: 44.0)

# Transmissions can return their count, the number of pulses
t1.count # => 4
# As well as their length in micros
t2.length # => 4100

# Transmissions can be split into mark/spaces with #tuples
t1.tuples # => [[500, 1000],[600, 2000]]

# Mathematical operators are implemented to simplify transformation

# Add two Transmissions to combine their data
t3 = t1 + LilBlaster::Transmission.new(data: [700, 4000, 800, 8000])
t3.tuples # => [[500, 1000],[600, 2000],[700, 4000],[800, 8000]]

# Multiply a Transmission by an integer to repeat its data
t4 = t3 * 3
t4.count # => 24

```

### Protocols

The `Protocol` module collects different protocol implementations, which are subclasses of the `BaseProtocol` class. The module itself serves as an interface for matching transmissions to those protocols.

```ruby
# A Transmission in RC5 format
pulses = [
  4511, 4540, 517, 1732, 517, 1732, 517, 1732,
  517, 609, 517, 609, 517, 609, 517, 609,
  517, 609, 517, 1732, 517, 1732, 517, 1732,
  517, 609, 517, 609, 517, 609, 517, 609,
  517, 609, 517, 609, 517, 1732, 517, 609,
  517, 609, 517, 609, 517, 609, 517, 609,
  517, 609, 517, 1732, 517, 609, 517, 1732,
  517, 1732, 517, 1732, 517, 1732, 517, 1732,
  517, 1732, 517, 47_312
]

tr1 = LilBlaster::Transmission.new(data: pulses)

# Determine protocol from the data and return a symbol
LilBlaster::Protocol.identify(tr1) # => :Manchester

# Or directly decode with #identify!
protocol, command = LilBlaster::Protocol.identify!(tr1)

protocol.class # => LilBlaster::Protocol::Manchester
protocol.pulse_values # => {
                      #      :header => [4511, 4540],
                      #      :zero => [517, 609],
                      #      :one => [517, 1732]
                      #    }

command.to_s(16) # => "40bf"

# Once a protocol is derived, you can encode data using it
tr2 = protocol.encode(command)
tr1 == tr2 # => true

# Or get a string representation
protocol.to_bytestring(command) # => "11100000111000000100000010111111"

```

### Codexes

The `Codex` class provides a way to collect codes that use the same protocol, allowing the organizing and sharing of codes for devices.

```ruby
# Creating a codex without a protocol
codex = LilBlaster::Codex.new(remote_name: 'example')

# You can manually specify a protocol by passing in arguments
proto_sym = :Manchester
proto_opts = {
  pulse_values: {
    header: [4511, 4540],
    zero: [517, 609],
    one: [517, 1732]
  },
  gap: 47_312,
  system_data: 57_568
}

codex = LilBlaster::Codex.new(
  remote_name: 'example',
  protocol: proto_sym,
  protocol_options: proto_opts
)

# Or directly passing an instance
proto_obj = LilBlaster::Protocol[proto_sym].new(proto_opts)
codex = LilBlaster::Codex.new(
  remote_name: 'example',
  protocol: proto_obj
)

# Codes can be added directly
codex[:power] = 16_575

# Or by using the #append method, which accepts multiple data formats

raw = LilBlaster::Transmission.new(
  data: [39, 325, 1128, 203, 159, 324, 39, 39]
)

codex.append(transmission: proto_obj.encode(57_375), as: :volume_up)
codex.append(data: 14_025, key: :red)
codex.append(raw_transmission: raw, name: :b1)

# Using #append can also automatically infer a protocol from a transmission
LilBlaster::Codex.new
                 .append(transmission: proto_obj.encode(53_805))
                 .protocol
                 .nil? # => false

# Or manually apply / overwrite one
codex.append(
  transmission: proto_obj.encode(2295),
  as: :channel_down,
  replace_protocol: true
)

# An array value implies sending both codes
codex[:twofer] = [4096, 4112]

# To generate transmissions, pass the corresponding key to #call,
# values in codes will be handled based on type

# Transmissions are returned directly
codex.call(:b1).class # => LilBlaster::Transmission
# Arrays are turned into Transmissions which are then joined
codex.call(:twofer).count == (codex.(power).length * 2) # => true
# Others are passed to the protocol to encode and the result returned
LilBlaster::Protocol::Manchester.same_data?(
  codex.call(:power),
  proto_obj.encode(codex[:power])
) # => true

```

Also on this class are functions for saving, loading, and automatic loading of codexes based on configured values.

```ruby
# Codexes can be loaded from a filepath, and saved out again
c1 = LilBlaster::Codex.load('/path/on/system/example_codex.yml')
c1.save_file # => <File:/path/on/system/example_codex.yml (closed)>

# Codexes can be passed in as a YAML string and exported to one as well
c2 = LilBlaster::Codex.from_yaml(...)
c2.to_yaml # => "---\n..."

# Autoload based on the value set in ConfigFile for :codexes_dir
LilBlaster::Codex.autoload # => [<LilBlaster::Codex...>,...]

# Return a specific default codex based on the value set in ConfigFile
c3 = LilBlaster::Codex.default
c3.remote_name.match?(ConfigFile[:default_codex]) # => true

```
### Reader

Capturing transmissions is done with the `Reader` class, which handles interacting with the IR Receiver. At its most basic, you can block and record for a number of seconds or captured transmissions.

```ruby
# Everything captured in 4 seconds (including potential partials)
captures = LilBlaster::Reader.record(seconds: 4)

# Capture whole transmissions, splitting on the gaps
captures << LilBlaster::Reader.record(first: 4)

```

There are also functions for asynchronous polling, where captured transmissions are dumped into a buffer on the reader class. They can also optionally be yielded to observer objects, either raw or cooked.

```ruby
# Begin scanning with #continuous_scan
LilBlaster::Reader.continuous_scan

# Internally, transmissions remain stored in a buffer as they come in
LilBlaster::Reader.transmission_buffer.count # => 8

# Stop the scan with #stop_scan
LilBlaster::Reader.stop_scan

# You can also attach observers to the reader
class Watcher
  attr_reader :prefix

  def initialize(pr)
    @prefix = pr
  end

  def update(transmission)
    str = "Transmission received for #{prefix},"
    str += " length: #{transmission.length}"

    puts str
  end
end

w1 = Watcher.new('Alpha')

# Any object with a defined #update method is sent transmissions
LilBlaster::Reader.continuous_scan(observe_transmissions: w1)

# You can pass one or more watchers and they will all be sent updates.
# Any Method object can be a watcher, which will receive the transmission

ot = [
  Math.method(:log),
  proc { |t| $last = t }.method(:call),
  Watcher.new('Beta')
]

LilBlaster::Reader.continuous_scan(observe_transmissions: ot)

# Pausing the scan will retain the observers, but not poll for transmissions
LilBlaster::Reader.pause_scan && LilBlaster::Reader.scanning? # => false

# Paused scans can be resumed, and their observers start up again
LilBlaster::Reader.resume_scan && LilBlaster::Reader.scanning? # => true

# Stopping the scan clears the observers
LilBlaster::Reader.stop_scan && LilBlaster::Reader.scanning? # => nil

# You can also respond to codes instead of raw transmissions, by passing
# in a codex to handle them or using the default codex

seen = []

LilBlaster::Reader.continuous_scan(
  observe_codes: [seen.method(:<<), Kernel.method(:puts)],
  codex: LilBlaster::Codex.autoload.last
)

seen # => [:volume_up, :volume_up, :prev_channel]

```

### Blaster

The `Blaster` class handles sending out IR data from the LED, and handles codexes and transmissions as data sources.

```ruby
tr = LilBlaster::Transmission.new(data: Array.new(10, 500))

# Directly send a transmission
LilBlaster::Blaster.transmit(tr)

# Or send a code from a codex
cx = LilBlaster::Codex.new(codes: { power: 16575 }, protocol: ...)

LilBlaster::Blaster.send_code(:power, codex: cx)

# Without a codex argmument, attempts to use the default codex
LilBlaster::Blaster.send_code(:power)

# Also handles basic on, off and checking functions
LilBlaster::Blaster.turn_on? && LilBlaster::Blaster.on? # => true
LilBlaster::Blaster.turn_off? && LilBlaster::Blaster.off? # => true

```

### Buttons

Reading from the two physical buttons on the HAT is done with the `Buttons` class.

```ruby
# Basic input from buttons. With no argument, blocks until you press
# a button then returns an index
LilBlaster::Buttons.get_input 
# => 0

# With arguments for seconds, it will timeout if no button is pressed
Inkblot::Buttons.get_input(seconds: 10) 
# => nil if no button is pressed for 10 seconds

# It's also possible to get chords instead of single presses
Inkblot::Buttons.get_chord_input(count: 2, seconds: 5) 
# => [0, 1] or nil if none pressed in 5s

# Returning multiple distinct presses in a row
Inkblot::Buttons.get_multi_input(count: 5) 
# => [0, 1, 1, 1, 0]

# You can also record all button activity within a timeframe
Inkblot::Buttons.get_raw_input(samples: 2000, seconds: 10) 
# => [[0], [0, 1]...]

```

It's also possible to supply callback functions to the buttons to be run when they're pressed

```ruby
# Callback will run every time button is released after being pressed
LilBlaster::Buttons.start_callback(0) do |tick, level, pin, value|
  puts 'Button 1 Pressed!'
end

# For simple one liners, you can also use this syntax
LilBlaster::Buttons[0] = ->(*a) { puts 'Button 1 Pressed' }

# To stop a callback, run stop_callback
LilBlaster::Buttons.stop_callback(0)

# Callback functions are stored, so you can resume a callback with
LilBlaster::Buttons.resume_callback(0)

# And remove a callback entirely with
LilBlaster::Buttons.remove_callback(0)

# You can also stop and remove a callback with #[]= and nil
LilBlaster::Buttons[0] = nil

```

### Configuration
