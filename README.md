# Fusuma::Plugin::Sendkey [![Gem Version](https://badge.fury.io/rb/fusuma-plugin-sendkey.svg)](https://badge.fury.io/rb/fusuma-plugin-sendkey) [![Build Status](https://travis-ci.com/iberianpig/fusuma-plugin-sendkey.svg?branch=master)](https://travis-ci.com/iberianpig/fusuma-plugin-sendkey)

[Fusuma](https://github.com/iberianpig/fusuma) plugin to send keyboard events

* Emulate keyboard events with evdev
* This plugin is wayland compatible and alternative to xdotool

## Installation

Run the following code in your terminal.

### Install dependencies

```sh
$ sudo apt-get install libevdev-dev
```

### Install fusuma-plugin-sendkey

```sh
$ sudo gem install fusuma-plugin-sendkey
```


## List available keys

```sh
$ fusuma-sendkey -l
```

## Run fusuma-sendkey on Terminal

* `fusuma-sendkey` command is available on your terminal
* `fusuma-sendkey` can send multiple key events
* Combine keys for pressing the same time with `+` 


```sh
$ fusuma-sendkey LEFTCTRL+T # press ctrl key + t key
```


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

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/iberianpig/fusuma-plugin-sendkey. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Fusuma::Plugin::Sendkey project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/iberianpig/fusuma-plugin-sendkey/blob/master/CODE_OF_CONDUCT.md).
