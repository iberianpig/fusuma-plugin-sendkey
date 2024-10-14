# frozen_string_literal: true

require "revdev"
require "set"
require_relative "linux/input"

module Fusuma
  module Plugin
    module Sendkey
      # handle Evdev device
      class Device
        include Linux::INPUT

        def initialize(path:)
          @evdev = Revdev::EventDevice.new(path)
          @capabilities = Set.new
        end

        attr_reader :capabilities

        def path
          raise "Device path is not found" if @evdev.nil?

          @path ||= @evdev.file.path
        end

        def write_event(event)
          @evdev.write_input_event(event)
        end

        def reload_capability
          @capabilities.clear

          buf = fetch_capabilities
          buf.unpack("C*").each_with_index do |byte, i|
            8.times do |bit| # 0..7
              if byte[bit] != 0
                @capabilities << (i * 8 + bit)
              end
            end
          end
          @capabilities
        end

        private

        def fetch_capabilities
          file = File.open(path, "r")
          buf = +"" # unfreeze string

          # EVIOCGBIT: Get the bit mask of the event types supported by the input device.
          # EV_KEY: The event type is EV_KEY, which means that the device supports key events.
          # KEY_CNT / 8: The number of bytes required to store the bit mask of the key codes.
          # file.ioctl: Get the bit mask of the key codes supported by the input device.
          file.ioctl(EVIOCGBIT(EV_KEY, KEY_CNT / 8), buf)
          buf
        end
      end
    end
  end
end
