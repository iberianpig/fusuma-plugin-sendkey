# frozen_string_literal: true

require "revdev"
require "fusuma/device"

require_relative "device"

module Fusuma
  module Plugin
    module Sendkey
      # Emulate Keyboard
      class Keyboard
        INTERVAL = 0.03

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

        def self.find_device(name_patterns:)
          Fusuma::Device.reset

          Array(name_patterns).each do |name_pattern|
            fusuma_device = Fusuma::Device.all.find { |d|
              next unless d.capabilities.include?("keyboard")

              d.name.match(/#{name_pattern}/)
            }

            if fusuma_device
              MultiLogger.info "sendkey: Keyboard: #{fusuma_device.name}"
              return Device.new(path: "/dev/input/#{fusuma_device.id}")
            end
            warn "sendkey: Keyboard: /#{name_pattern}/ is not found"
          end

          exit(1)
        end

        def initialize(device:)
          @device = device
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

          param_keycodes = param_to_codes(param)
          type_keycodes = param_keycodes - param_to_codes(keep)

          clear_keycodes =
            case clear
            when true
              MODIFIER_KEY_CODES
            when :none, false
              []
            else
              # release keys specified by clearmodifiers
              param_to_codes(clear)
            end

          clear_modifiers(clear_keycodes - param_keycodes)

          type_keycodes.each { |keycode| keydown(keycode) && key_sync }
          sleep(INTERVAL)
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
            keycodes = param_to_codes(param)
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
        end

        def capabilities
          return @capabilities if defined?(@capabilities)

          @capabilities = Set.new.tap do |set|
            @device.reload_capability.each do |id|
              code_sym = Revdev::REVERSE_MAPS[:KEY][id]
              set << code_sym if code_sym
            end
          end
        end

        def support?(code)
          @supported_code ||= {}
          @supported_code[code] ||= find_code(code)
        end

        def warn_undefined_codes(code)
          candidates = search_codes(code).map { |c| remove_prefix(c.to_s) }

          warn "Did you mean? #{candidates.join(" / ")}" unless candidates.empty?

          warn "sendkey: #{remove_prefix(code)} is unsupported."
        end

        def search_codes(code)
          capabilities.select { |c| c[code] }
        end

        def find_code(code)
          result = capabilities.find { |c| c == code.to_sym }

          warn_undefined_codes(code) unless result
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
        def param_to_codes(param)
          param.split("+").map { |keyname| add_prefix(keyname) }
        end

        private

        def add_prefix(code)
          code.upcase!
          if code.start_with?("BTN_")
            code
          else
            "KEY_#{code}"
          end
        end

        def remove_prefix(keycode)
          keycode.gsub("KEY_", "")
        end
      end
    end
  end
end
