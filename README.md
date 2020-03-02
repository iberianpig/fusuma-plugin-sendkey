# Fusuma::Plugin::Sendkey [![Gem Version](https://badge.fury.io/rb/fusuma-plugin-sendkey.svg)](https://badge.fury.io/rb/fusuma-plugin-sendkey) [![Build Status](https://travis-ci.com/iberianpig/fusuma-plugin-sendkey.svg?branch=master)](https://travis-ci.com/iberianpig/fusuma-plugin-sendkey)

[Fusuma](https://github.com/iberianpig/fusuma) plugin that sending virtual keyboard events

* Send emulate keyboard events with evemu-event
* This plugin replaces xdotool

## Installation

Run the following code in your terminal.

### Install dependencies

```sh
$ sudo apt-get install evemu-tools libevdev-dev
```

### Install fusuma-plugin-sendkey

```sh
$ gem install fusuma-plugin-sendkey
```


## List avaiable keys

```sh
$ fusuma-sendkey -l
```

## Run fusuma-sendkey on Terminal

* `fusuma-sendkey` can emulate keyboard inputs as a command
* Combine keys for pressing the same time with `+` 


```sh
$ fusuma-sendkey LEFTCTRL+T
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
