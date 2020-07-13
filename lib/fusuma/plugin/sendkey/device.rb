# frozen_string_literal: true

module Fusuma
  module Plugin
    module Sendkey
      # handle Evdev device
      class Device
        def initialize(path:)
          @evdev = Revdev::EventDevice.new(path)
        end

        def path
          raise 'Device path is not found' if @evdev.nil?

          @path ||= @evdev.file.path
        end

        def write_event(event)
          @evdev.write_input_event(event)
        end
      end
    end
  end
end
