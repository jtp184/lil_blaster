# Setting up Raspberry Pi

This is a simple start guide to setting up Raspberry Pi for use with LilBlaster

## Flashing

See the [Raspberry Pi Documentation](https://www.raspberrypi.org/documentation/installation/installing-images/README.md) for details on downloading images and flashing them to cards.

## Wifi setup

Create a [`wpa_supplicant.conf`](https://wiki.archlinux.org/title/wpa_supplicant) file and load it onto the flashed boot drive

## Boot Config

Modify the `config.txt` and set `dtparam=spi on`. Touch a file named `ssh` in the boot directory to enable ssh on boot

## Installing Dependencies and gem

SSH into the pi and run

```bash
sudo apt-get update
sudo apt-get install ruby-full
sudo gem install bundler rake pigpio

mkdir -p ~/repos && cd ~/repos && git clone https://github.com/jtp184/lil_blaster.git
cd lil_blaster && bundle && sudo rake install
```