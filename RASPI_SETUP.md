# Setting up Raspberry Pi

This is a simple start guide to setting up Raspberry Pi for use with taptag

## Flashing

See the [Raspberry Pi Documentation](https://www.raspberrypi.org/documentation/installation/installing-images/README.md) for details on downloading images and flashing them to cards.

## Wifi setup

Run `bin/pi/wpa_config` to enter wifi credentials. This will save a `wpa_supplicant.conf` file. You can also create one manually if you'd like.

![wpa_config](https://justinp-io-production.s3.amazonaws.com/store/1c97d2fc7d5ba62ef9b7ae0ecff7991e.png)

## Boot Config

Ensure that the boot volume is mounted. Run `bin/pi/boot_config`, which will set SSH and SPI settings, and copy your `wpa_supplicant.conf` file.

![boot_config](https://justinp-io-production.s3.amazonaws.com/store/4be1b791d8c2c40fdf861e50ed80b423.png)

## Installing Dependencies

Run `bin/pi/install_deps`. You can install various needed dependencies remotely with this script, including Ruby, the gem itself, and compiling / installing the waveshare libraries on the pi itself.

![install_deps](https://justinp-io-production.s3.amazonaws.com/store/b485a3b2ce85782d9ab6ce2379699607.png)