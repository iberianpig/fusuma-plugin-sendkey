# frozen_string_literal: true

require 'evdev'

module Fusuma
  module Plugin
    module Sendkey
      # handle Evdev device
      class Device
        def initialize(path: nil)
          return if path && (@evdev = Evdev.new(path))

          (0..99).lazy.find do |i|
            evdev = Evdev.new("/dev/input/event#{i}")
            # NOTE: find keyboard device
            @evdev = evdev if evdev.supports_event?('KEY_LEFTALT')
          rescue Errno::ENOENT # No such file or directory
            false
            # TODO: rescue Errno::EACCES
          end
        end

        def path
          raise 'Keyboard is not found' if @evdev.nil?

          @path ||= @evdev.file.path
        end

        def support?(keycode)
          @evdev.supports_event?(keycode)
        rescue NameError
          false
        end
      end
    end
  end
end
