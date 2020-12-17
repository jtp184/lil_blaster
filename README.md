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

## CLI

## Usage

### Documentation

All methods and classes are RDoc documented at https://jtp184.github.io/lil_blaster

### Transmissions

A Transmission wraps a collection of pulse timings, with methods to help analyze them

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
### Codexes
### Buttons
### Blaster
### Reader
### Configuration
