# frozen_string_literal: true

require 'evdev'

# handle Evdev device
class Device
  attr_reader :device_id
  def initialize(path: nil)
    return if path && (@evdev = Evdev.new(path))

    (0..99).lazy.find do |i|
      begin
        evdev = Evdev.new("/dev/input/event#{i}")
        @evdev = evdev if evdev.supports_event?(convert_keycode('LEFTALT'))
      rescue Errno::ENOENT # No such file or directory
        false
        # TODO: rescue Errno::EACCES
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
