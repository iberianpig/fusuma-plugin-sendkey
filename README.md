# Fusuma::Plugin::Sendkey [![Gem Version](https://badge.fury.io/rb/fusuma-plugin-sendkey.svg)](https://badge.fury.io/rb/fusuma-plugin-sendkey) [![Build Status](https://travis-ci.com/iberianpig/fusuma-plugin-sendkey.svg?branch=master)](https://travis-ci.com/iberianpig/fusuma-plugin-sendkey)

[Fusuma](https://github.com/iberianpig/fusuma) plugin to send keyboard events

* Low-latency key event emulation with evdev
* Alternative to xdotool available for X11 and Wayland

## Installation

Run the following code in your terminal.

### 1. Install dependencies

#### For Debian Based Distros (Ubuntu, Debian, Mint, Pop!_OS)

**NOTE: If you have installed ruby by apt, you must install ruby-dev.**
```sh
$ sudo apt-get install libevdev-dev ruby-dev build-essential
```

#### For Arch Based Distros (Manjaro, Arch)

```zsh
$ sudo pacman -S libevdev base-devel
```

### 2. Install fusuma-plugin-sendkey


**Note For Arch Based Distros:** By default in Arch Linux, when running `gem`, gems are installed per-user (into `~/.gem/ruby/`), instead of system-wide (into `/usr/lib/ruby/gems/`). This is considered the best way to manage gems on Arch, because otherwise they might interfere with gems installed by Pacman. (From Arch Wiki)

To install gems system-wide, see any of the methods listed on [Arch Wiki](https://wiki.archlinux.org/index.php/ruby#Installing_gems_system-wide)


```sh
$ sudo gem install revdev
$ sudo gem install bundler
$ sudo gem install fusuma-plugin-sendkey
```

## List available keys

```sh
$ fusuma-sendkey -l
```
If you want to look up a specific key, like the next song or the previous song, the `grep -i` refinement search is useful.

```sh
$ fusuma-sendkey -l | grep -i song
NEXTSONG
PREVIOUSSONG
```

## Run fusuma-sendkey on Terminal

* `fusuma-sendkey` command is available on your terminal
* `fusuma-sendkey` supports modifier keys and multiple key presses.
Combine keys for pressing the same time with `+` 


```sh
$ fusuma-sendkey LEFTCTRL+T # press ctrl key + t key
```

Some of the keys found with `fusuma-sendkey -l` may actually be invalid keys.
So test it once with `fusuma-sendkey <KEYCODE>` and then add it to config.yml.


## Add sendkey properties to config.yml

Add `sendkey:` property in `~/.config/fusuma/config.yml`.

lines beginning from `#` are comments

```yaml
swipe:
  3:
    left:
      sendkey: "LEFTALT+RIGHT" # history back
    right:
      sendkey: "LEFTALT+LEFT" # history forward
    up:
      sendkey: "LEFTCTRL+T" # open new tab
    down:
      sendkey: "LEFTCTRL+W" # close tab
```


### Specify keyboard by device name

If you got following error message, try to set your keyboard name to `plugin.executors.sendkey_executor.device_name` on config.yml

```shell
$ fusuma-sendkey -l
sendkey: Keyboard: /keyboard|Keyboard|KEYBOARD/ is not found
```

Set the following options to recognize keyboard only for the specified keyboard device.
Open `~/.config/fusuma/config.yml` and add the following code at the bottom.

```yaml
plugin:
  executors:
    sendkey_executor:
      device_name: 'YOUR KEYBOARD NAME'
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/iberianpig/fusuma-plugin-sendkey. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Fusuma::Plugin::Sendkey project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/iberianpig/fusuma-plugin-sendkey/blob/master/CODE_OF_CONDUCT.md).
