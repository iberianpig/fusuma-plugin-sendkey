# frozen_string_literal: true

require "revdev"
require "set"

module Fusuma
  module Plugin
    module Sendkey
      # handle Evdev device
      class Device
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

        EVIOCGBIT = 2153792801

        def fetch_capabilities
          file = File.open(path, "r")
          buf = +"" # unfreeze string
          file.ioctl(EVIOCGBIT, buf)
          buf
        end
      end
    end
  end
end
