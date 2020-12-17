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

## Usage

### Documentation

All methods and classes are RDoc documented at https://jtp184.github.io/lil_blaster