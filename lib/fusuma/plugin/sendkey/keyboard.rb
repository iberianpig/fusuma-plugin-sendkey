# frozen_string_literal: true

require 'evdev'

# Emulate Keyboard
class Keyboard
  def initialize
    @device = Device.new
    @path = @device.path
  end

  # @param param [String]
  def type_command(param:)
    return unless param.is_a?(String)

    codes = param.split('+')
    press_commands = codes.map { |code| press_command(code) }
    release_commands = codes.reverse.map { |code| release_command(code) }

    (press_commands | release_commands).join(' ; ')
  end

  def press_command(code)
    return unless support?(code)

    @device.emulate(code: code, press: true)
  end

  def release_command(code)
    return unless support?(code)

    @device.emulate(code: code, press: false)
  end

  def support?(code)
    @supported_code ||= {}
    @supported_code[:code] ||= if @device.support?(code)
                                 true
                               else
                                 warn "Key: #{code} is unsupported"
                                 exit 1
                               end
  end

  def available_codes
    @device.search_codes
  end

  # handle Evdev device
  class Device
    attr_reader :device_id
    def initialize
      (0..99).lazy.find do |i|
        begin
          evdev = Evdev.new("/dev/input/event#{i}")
          @evdev = evdev if evdev.supports_event?(convert_keycode('LEFTALT'))
        rescue Errno::ENOENT
          false
        end
      end
    end

    def path
      raise 'Keyboard is not found' if @evdev.nil?

      @path ||= @evdev.file.path
    end

    def support?(code)
      keycode = convert_keycode(code)
      @evdev.supports_event?(keycode)
    rescue NameError
      candidates = search_codes(code: code)

      warn "Did you mean? #{candidates.join(' / ')}" unless candidates.empty?

      false
    end

    def search_codes(code: nil)
      query = code&.upcase
      LinuxInput.constants
                .select { |c| c[/KEY_.*#{query}.*/] }
                .select { |c| @evdev.supports_event?(c) }
                .map { |c| c.to_s.gsub('KEY_', '') }
    end

    def emulate(code:, press: true)
      keycode = convert_keycode(code)
      v = press ? 1 : 0
      "evemu-event #{path} --type EV_KEY --code #{keycode} --value #{v} --sync"
    end

    private

    def convert_keycode(code)
      "KEY_#{code.upcase}"
    end
  end
end
