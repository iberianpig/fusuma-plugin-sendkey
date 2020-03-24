# frozen_string_literal: true

require 'linux_input'
require 'fcntl'
require_relative './device.rb'

module Fusuma
  module Plugin
    module Sendkey
      # Emulate Keyboard
      class Keyboard
        def initialize(device: nil)
          @device = device || Device.new
        end

        # @param param [String]
        def type(param:)
          return unless param.is_a?(String)

          keycodes = split_param(param)

          clear_modifiers
          keycodes.each { |keycode| key_event(keycode: keycode, press: true) }
          key_sync(press: true)
          keycodes.reverse.map { |keycode| key_event(keycode: keycode, press: false) }
          key_sync(press: false)
          device_file.close
        end

        # @param param [String]
        def valid?(param:)
          return unless param.is_a?(String)

          keycodes = split_param(param)
          keycodes.all? { |keycode| support?(keycode) }
        end

        def device_file
          return @device_file if @device_file && !@device_file.closed?

          @device_file = File.open(@device.path, Fcntl::O_WRONLY | Fcntl::O_NDELAY)
        end

        def key_event(keycode:, press: true)
          event = LinuxInput::InputEvent.new
          event[:time] = LinuxInput::Timeval.new
          event[:time][:tv_sec] = Time.now.to_i
          event[:type] = LinuxInput::EV_KEY
          event[:code] = keycode_const(keycode)
          event[:value] = press ? 1 : 0
          device_file.syswrite(event.pointer.read_bytes(event.size))
        end

        def key_sync(press: true)
          event = LinuxInput::InputEvent.new
          event[:time] = LinuxInput::Timeval.new
          event[:time][:tv_sec] = Time.now.to_i
          event[:type] = LinuxInput::EV_SYN
          event[:code] = LinuxInput::SYN_REPORT
          event[:value] = press ? 1 : 0
          device_file.syswrite(event.pointer.read_bytes(event.size))
        end

        def support?(keycode)
          @supported_code ||= {}
          @supported_code[keycode] ||= if @device.support?(keycode)
                                         true
                                       else
                                         search_candidates(keycode: keycode)
                                         exit(1)
                                       end
        end

        def search_candidates(keycode:)
          candidates = search_codes(keycode: keycode)

          warn "Did you mean? #{candidates.join(' / ')}" unless candidates.empty?
          warn "sendkey: #{remove_prefix(keycode)} is unsupported."
        end

        def search_codes(keycode: nil)
          query = keycode&.upcase&.gsub('KEY_', '')
          LinuxInput.constants
                    .select { |c| c[/KEY_.*#{query}.*/] }
                    .select { |c| @device.support?(c) }
                    .map { |c| c.to_s.gsub('KEY_', '') }
        end

        def keycode_const(keycode)
          Object.const_get "LinuxInput::#{keycode}"
        end

        def clear_modifiers
          modifiers = %w[ CAPSLOCK LEFTALT LEFTCTRL LEFTMETA
                          LEFTSHIFT RIGHTALT RIGHTCTRL RIGHTSHIFT ]
          modifiers.each { |code| key_event(keycode: key_prefix(code), press: false) }
        end

        private

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
