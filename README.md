# Fusuma::Plugin::Sendkey [![Gem Version](https://badge.fury.io/rb/fusuma-plugin-sendkey.svg)](https://badge.fury.io/rb/fusuma-plugin-sendkey) [![Build Status](https://github.com/iberianpig/fusuma-plugin-sendkey/actions/workflows/main.yml/badge.svg)](https://github.com/iberianpig/fusuma-plugin-sendkey/actions/workflows/main.yml)

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

#### For Red Hat Based Distros (Fedora, RHEL)

```sh
$ sudo dnf install ruby-devel
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

## List Available Keys

```sh
$ fusuma-sendkey -l
```
To look up a specific key, such as the next or previous song, you can use the `grep -i` filter.

```sh
$ fusuma-sendkey -l | grep -i song
NEXTSONG
PREVIOUSSONG
```

## Running fusuma-sendkey on Terminal

* `fusuma-sendkey` command is available on your terminal for testing.
* `fusuma-sendkey` supports modifier keys and multiple key presses.
   - Combine keys for pressing the same time with `+` 
   - Separate keys for pressing sequentially with `,`

### Example (Sendkey with Modifier Keys)

```sh
$ fusuma-sendkey LEFTCTRL+T # Open a new tab
```

### Example (Sendkey with Multiple Key Presses)

```sh
$ fusuma-sendkey ["LEFTSHIFT+F10", "T", "ENTER", "ESC"] # Google Translate
```

Some of the keys found with `fusuma-sendkey -l` may actually be invalid keys.
So test them first with `fusuma-sendkey <KEYCODE>` before adding them to config.yml.


## Add Sendkey Properties to config.yml

Add the `sendkey:` property in your `~/.config/fusuma/config.yml`.

Lines beginning with `#` are comments.

```yaml
swipe:
  3:
    left:
      sendkey: "LEFTALT+RIGHT" # History back
    right:
      sendkey: "LEFTALT+LEFT" # History forward
    up:
      sendkey: "LEFTCTRL+T" # Open a new tab
    down:
      sendkey: "LEFTCTRL+W" # Close a tab

hold:
  3:
    sendkey: ["LEFTSHIFT+F10", "T", "ENTER", "ESC"] # Translate in Google Chrome
```

### clearmodifiers

- `clearmodifiers: true` option clears other modifier keys before sending

```yaml
swipe:
  4:
    up:
      keypress:
        LEFTSHIFT:
          sendkey: "LEFTMETA+DOWN"
          clearmodifiers: true # Clear LEFTSHIFT before sending LEFTMETA+DOWN
```

### Specify Keyboard by Device Name

If you encounter the following error message, please set your keyboard name in `plugin.executors.sendkey_executor.device_name` in config.yml.

```sh
$ fusuma-sendkey -l
sendkey: Keyboard: /keyboard|Keyboard|KEYBOARD/ is not found
```

Add the following code to the bottom of `~/.config/fusuma/config.yml` to recognize only the specified keyboard device.

```yaml
plugin:
  executors:
    sendkey_executor:
      device_name: 'YOUR KEYBOARD NAME'
```

**Note**: If [fusuma-plugin-remap](https://github.com/iberianpig/fusuma-plugin-remap) is available, it will automatically connect to `fusuma_virtual_keyboard`, so the `device_name` option is not required.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/iberianpig/fusuma-plugin-sendkey. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Fusuma::Plugin::Sendkey project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/iberianpig/fusuma-plugin-sendkey/blob/master/CODE_OF_CONDUCT.md).
