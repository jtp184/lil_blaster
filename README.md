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

# You can optionally specify a carrier wave frequency in kHz, with 38.0 being the default
t2 = LilBlaster::Transmission.new(data: d, carrier_wave: 44.0)

# Transmissions can return their count, the number of pulses
t1.count # => 4
# As well as their length in micros
t2.length # => 4100

# Transmissions can be split into their respective mark/spaces with #tuples
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
protocol.pulse_values # => {:header => [4511, 4540], :zero => [517, 609], :one => [517, 1732]}

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

# You can manually specify a protocol by passing in arguments to construct it
proto_sym = :Manchester
proto_opts = {
  pulse_values: {:header => [4511, 4540], :zero => [517, 609], :one => [517, 1732]},
  gap: 47_312,
  system_data: 57_568
}

codex = LilBlaster::Codex.new(remote_name: 'example', protocol: proto_sym, protocol_options: proto_opts)

# Or directly passing an instance
proto_obj = LilBlaster::Protocol[proto_sym].new(proto_opts)
codex = LilBlaster::Codex.new(remote_name: 'example', protocol: proto_obj)

# Codes can be added directly
codex[:power] = 16575

# Or by using the #append method, which accepts multiple data formats
codex.append(transmission: LilBlaster::Transmission.new(data: ...), as: :volume_up)
codex.append(data: 8756, key: :ok)
codex.append(raw_transmission: LilBlaster::Transmission.new(data: ...), name: :b4)

# Using #append can also automatically infer a protocol from a transmission
LilBlaster::Codex.new.append(transmission: LilBlaster::Transmission.new(data: ...)).protocol.nil? # => false
# Or manually apply / overwrite one
codex.append(transmission: LilBlaster::Transmission.new(data: ...), as: :input, replace_protocol: true)

# Array values for codes are also supported, and are turned into a joined transmission
codex[:twofer] = [4096, 4112]

# To generate transmissions, pass the corresponding key to #call, values in codes will be handled based on type

# Transmissions are returned directly
codex.call(:b4).class # => LilBlaster::Transmission
# Arrays are turned into Transmissions which are then joined
codex.call(:twofer).count == (codex.(power).length * 2) # => true
# Other argument types are passed to the #encode method on the protocol and the result returned
codex.call(:power) # => #<LilBlaster::Transmission data=[4511, 4540, 517, 1732...]>

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

### Buttons
### Blaster
### Reader
### Configuration
