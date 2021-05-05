# frozen_string_literal: true

require 'revdev'
require 'fusuma/device'

require_relative './device'

module Fusuma
  module Plugin
    module Sendkey
      # Emulate Keyboard
      class Keyboard
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

        def initialize(name_pattern: nil)
          name_pattern ||= 'keyboard|Keyboard|KEYBOARD'
          device = find_device(name_pattern: name_pattern)

          if device.nil?
            warn "sendkey: Keyboard: /#{name_pattern}/ is not found"
            exit(1)
          end

          @device = Device.new(path: "/dev/input/#{device.id}")
        end

        attr_reader :device

        # @param param [String]
        # @param keep [String]
        def type(param:)
          return unless param.is_a?(String)

          param_keycodes = split_param(param)
          clear_modifiers(MODIFIER_KEY_CODES - param_keycodes)
          param_keycodes.each { |keycode| key_event(keycode: keycode, press: true) }
          key_sync(press: true)
          param_keycodes.reverse.each { |keycode| key_event(keycode: keycode, press: false) }
          key_sync(press: false)
        end

        # @param param [String]
        def valid?(param:)
          return unless param.is_a?(String)

          keycodes = split_param(param)
          keycodes.all? { |keycode| support?(keycode) }
        end

        def key_event(keycode:, press: true)
          event = Revdev::InputEvent.new(
            nil,
            Revdev.const_get(:EV_KEY),
            Revdev.const_get(keycode),
            press ? 1 : 0
          )
          @device.write_event(event)
        end

        def key_sync(press: true)
          event = Revdev::InputEvent.new(
            nil,
            Revdev.const_get(:EV_SYN),
            Revdev.const_get(:SYN_REPORT),
            press ? 1 : 0
          )
          @device.write_event(event)
        end

        def support?(keycode)
          @supported_code ||= {}
          @supported_code[keycode] ||= if find_code(keycode: keycode)
                                         true
                                       else
                                         search_candidates(keycode: keycode)
                                       end
        end

        def search_candidates(keycode:)
          query = keycode&.upcase&.gsub('KEY_', '')

          candidates = search_codes(query: query)

          warn "Did you mean? #{candidates.join(' / ')}" unless candidates.empty?
          warn "sendkey: #{remove_prefix(keycode)} is unsupported."
        end

        def search_codes(query: nil)
          Revdev.constants
                .select { |c| c[/KEY_.*#{query}.*/] }
                .map { |c| c.to_s.gsub('KEY_', '') }
        end

        def find_code(keycode: nil)
          query = keycode&.upcase&.gsub('KEY_', '')

          Revdev.constants.find { |c| c == "KEY_#{query}".to_sym }
        end

        def keycode_const(keycode)
          Object.const_get "LinuxInput::#{keycode}"
        end

        # @param [Array<String>] keycodes to be released
        def clear_modifiers(keycodes)
          keycodes.each { |code| key_event(keycode: code, press: false) }
        end

        private

        def find_device(name_pattern:)
          Fusuma::Device.all.find { |d| d.name.match(/#{name_pattern}/) }
        end

        def split_param(param)
          param.split('+').map { |code| key_prefix(code) }
        end

        def key_prefix(code)
          "KEY_#{code.upcase}"
        end

        def remove_prefix(keycode)
          keycode.gsub('KEY_', '')
        end
      end
    end
  end
end
