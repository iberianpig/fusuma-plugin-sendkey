# frozen_string_literal: true

require "revdev"
require "fusuma/device"

require_relative "device"

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
          Fusuma::Device.reset
          Fusuma::Device.all.find { |d|
            next unless /keyboard/.match?(d.capabilities)

            d.name.match(/#{name_pattern}/)
          }
        end

        def initialize(name_pattern: nil)
          device = Keyboard.find_device(name_pattern: name_pattern)

          if device.nil?
            warn "sendkey: Keyboard: /#{name_pattern}/ is not found"
            exit(1)
          end
          MultiLogger.info "sendkey: Keyboard: #{device.name}"

          @device = Device.new(path: "/dev/input/#{device.id}")
        end

        # @param params [Array]
        def types(args)
          return unless args.is_a?(Array)

          args.each do |arg|
            case arg
            when String
              type(param: arg)
            when Hash
              type(**arg)
            end
          end
        end

        # @param param [String] key names separated by '+' to type
        # @param keep [String] key names separated by '+' to keep
        # @param clear [String, Symbol, TrueClass] key names separated by '+' to clear or :all to release all modifiers
        def type(param:, keep: "", clear: :none)
          return unless param.is_a?(String)

          param_keycodes = param_to_keycodes(param)
          type_keycodes = param_keycodes - param_to_keycodes(keep)

          clear_keycodes =
            case clear
            when true
              MODIFIER_KEY_CODES
            when :none, false
              []
            else
              # release keys specified by clearmodifiers
              param_to_keycodes(clear)
            end

          clear_modifiers(clear_keycodes - param_keycodes)

          type_keycodes.each { |keycode| keydown(keycode) && key_sync }
          type_keycodes.reverse_each { |keycode| keyup(keycode) && key_sync }
        end

        def keydown(keycode)
          send_event(code: keycode, press: true)
        end

        def keyup(keycode)
          send_event(code: keycode, press: false)
        end

        # @param param [String]
        def valid?(params)
          case params
          when Array
            params.all? { |param| valid?(param) }
          when String
            param = params
            keycodes = param_to_keycodes(param)
            keycodes.all? { |keycode| support?(keycode) }
          else
            MultiLogger.error "sendkey: Invalid config: #{params}"
            nil
          end
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
          Object.const_get "Revdev::#{keycode}"
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
