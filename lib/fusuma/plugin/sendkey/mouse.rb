# frozen_string_literal: true

require 'revdev'
require 'fusuma/device'

require_relative './device'

module Fusuma
  module Plugin
    module Sendkey
      # Emulate Mouse
      class Mouse
        INTERVAL = 0.01

        def self.find_device(name_pattern:)
          Fusuma::Device.all.find { |d| d.name.match(/#{name_pattern}/) }
        end

        def initialize(name_pattern: nil)
          name_pattern ||= 'mouse|Mouse|MOUSE'
          device = Mouse.find_device(name_pattern: name_pattern)

          if device.nil?
            warn "sendkey: Mouse: /#{name_pattern}/ is not found"
            exit(1)
          end

          @device = Device.new(path: "/dev/input/#{device.id}")
        end

        # @param param [String]
        def click_button(param:)
          param_codes = param_to_codes(param)
          param_codes.each { |code| down(code) && sync }
          param_codes.reverse.each { |code| up(code) && sync }
        end

        def down(code)
          send_event(code: code, press: true)
        end

        def up(code)
          send_event(code: code, press: false)
        end

        # @param param [String]
        def valid?(param:)
          return unless param.is_a?(String)

          codes = param_to_codes(param)
          codes.all? { |c| support?(c) }
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

        def sync
          event = Revdev::InputEvent.new(
            nil,
            Revdev.const_get(:EV_SYN),
            Revdev.const_get(:SYN_REPORT),
            0
          )
          @device.write_event(event)
          sleep(INTERVAL)
        end

        def support?(code)
          @supported_code ||= {}
          @supported_code[code] ||= find_code(code: code)
        end

        def warn_undefined_codes(code:)
          query = code&.upcase&.gsub('BTN_', '')

          candidates = search_codes(query: query)

          warn "Did you mean? #{candidates.join(' / ')}" unless candidates.empty?
          warn "sendkey: #{remove_prefix(code)} is unsupported."
        end

        def search_codes(query: nil)
          Revdev.constants
                .select { |c| c[/BTN_.*#{query}.*/] }
                .map { |c| c.to_s.gsub('BTN_', '') }
        end

        def find_code(code: nil)
          query = code&.upcase&.gsub('BTN_', '')

          result = Revdev.constants.find { |c| c == "BTN_#{query}".to_sym }

          warn_undefined_codes(code: code) unless result
          result
        end

        def code_const(code)
          Object.const_get "LinuxInput::#{code}"
        end

        # @param [String]
        # @return [Array<String>]
        def param_to_codes(param)
          param.split('+').map { |name| add_prefix(name) }
        end

        private

        def add_prefix(name)
          "BTN_#{name.upcase}"
        end

        def remove_prefix(code)
          code.gsub('BTN_', '')
        end
      end
    end
  end
end
