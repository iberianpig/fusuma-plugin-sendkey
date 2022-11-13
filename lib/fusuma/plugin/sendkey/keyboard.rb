# frozen_string_literal: true

require "revdev"
require "fusuma/device"

require_relative "./device"

module Fusuma
  module Plugin
    module Sendkey
      # Emulate Keyboard
      class Keyboard
        INTERVAL = 0.01

        MODIFIER_KEY_CODES = %w[
          KEY_CAPSLOCK
          KEY_LEFTALT
          KEY_LEFTCTRL
          KEY_LEFTMETA
          KEY_LEFTSHIFT
          KEY_RIGHTALT
          KEY_RIGHTCTRL
          KEY_RIGHTSHIFT
          KEY_RIGHTMETA
        ].freeze

        def self.find_device(name_pattern:)
          Fusuma::Device.all.find { |d| d.name.match(/#{name_pattern}/) }
        end

        def initialize(name_pattern: nil)
          name_pattern ||= "keyboard|Keyboard|KEYBOARD"
          device = Keyboard.find_device(name_pattern: name_pattern)

          if device.nil?
            warn "sendkey: Keyboard: /#{name_pattern}/ is not found"
            exit(1)
          end

          @device = Device.new(path: "/dev/input/#{device.id}")
        end

        # @param param [String]
        def type(param:)
          return unless param.is_a?(String)

          param_keycodes = param_to_keycodes(param)
          # release other modifier keys before sending key
          clear_modifiers(MODIFIER_KEY_CODES - param_keycodes)
          param_keycodes.each { |keycode| keydown(keycode) && key_sync }
          param_keycodes.reverse_each { |keycode| keyup(keycode) && key_sync }
        end

        def keydown(keycode)
          send_event(code: keycode, press: true)
        end

        def keyup(keycode)
          send_event(code: keycode, press: false)
        end

        # @param param [String]
        def valid?(param:)
          return unless param.is_a?(String)

          keycodes = param_to_keycodes(param)
          keycodes.all? { |keycode| support?(keycode) }
        end

        def send_event(code:, press: true)
          event = Revdev::InputEvent.new(
            nil,
            Revdev.const_get(:EV_KEY),
            Revdev.const_get(code),
            press ? 1 : 0
          )
          @device.write_event(event)
        end

        def key_sync
          event = Revdev::InputEvent.new(
            nil,
            Revdev.const_get(:EV_SYN),
            Revdev.const_get(:SYN_REPORT),
            0
          )
          @device.write_event(event)
          sleep(INTERVAL)
        end

        def support?(keycode)
          @supported_code ||= {}
          @supported_code[keycode] ||= find_code(keycode: keycode)
        end

        def warn_undefined_codes(keycode:)
          query = keycode&.upcase&.gsub("KEY_", "")

          candidates = search_codes(query: query)

          warn "Did you mean? #{candidates.join(" / ")}" unless candidates.empty?
          warn "sendkey: #{remove_prefix(keycode)} is unsupported."
        end

        def search_codes(query: nil)
          Revdev.constants
            .select { |c| c[/KEY_.*#{query}.*/] }
            .map { |c| c.to_s.gsub("KEY_", "") }
        end

        def find_code(keycode: nil)
          query = keycode&.upcase&.gsub("KEY_", "")

          result = Revdev.constants.find { |c| c == "KEY_#{query}".to_sym }

          warn_undefined_codes(keycode: keycode) unless result
          result
        end

        def keycode_const(keycode)
          Object.const_get "LinuxInput::#{keycode}"
        end

        # @param [Array<String>] keycodes to be released
        def clear_modifiers(keycodes)
          keycodes.each { |code| send_event(code: code, press: false) }
        end

        # @param [String]
        # @return [Array<String>]
        def param_to_keycodes(param)
          param.split("+").map { |keyname| add_key_prefix(keyname) }
        end

        private

        def add_key_prefix(code)
          "KEY_#{code.upcase}"
        end

        def remove_prefix(keycode)
          keycode.gsub("KEY_", "")
        end
      end
    end
  end
end
