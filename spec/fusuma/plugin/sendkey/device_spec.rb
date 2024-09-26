# frozen_string_literal: true

require "spec_helper"

require "./lib/fusuma/plugin/sendkey/device"

module Fusuma
  module Plugin
    module Sendkey
      RSpec.describe Device do
        let(:mock_evdev) { instance_double("Revdev::EventDevice") }
        let(:mock_file) { instance_double("File") }
        let(:device_path) { "/dev/input/event0" }
        let(:device) { Device.new(path: device_path) }
        let(:mock_capabilities) {
          [254, 255, 255, 255, 255, 255, 255, 255, 255, 255, 239, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 7, 255, 255, 255, 255, 255, 255, 0, 255, 3, 255, 0, 0, 0, 0, 0, 0, 0, 0, 0, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 7, 15, 0, 255, 255, 31, 0, 254, 7, 255, 15, 255, 7, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 128, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0].pack("C*")
        }

        before do
          allow(Revdev::EventDevice).to receive(:new).with(device_path).and_return(mock_evdev)
          allow(mock_evdev).to receive(:file).and_return(mock_file)
        end

        describe "#path" do
          it "returns the device path" do
            allow(mock_file).to receive(:path).and_return(device_path)
            expect(device.path).to eq(device_path)
          end

          it "raises an error if the evdev is nil" do
            allow(mock_evdev).to receive(:nil?).and_return(true)
            expect { device.path }.to raise_error("Device path is not found")
          end
        end

        describe "#write_event" do
          it "writes an input event to the evdev device" do
            event = double("event")
            expect(mock_evdev).to receive(:write_input_event).with(event)
            device.write_event(event)
          end
        end

        describe "#reload_capability" do
          it "reloads the capabilities from the evdev device" do
            allow(device).to receive(:fetch_capabilities).and_return(mock_capabilities)

            expect(device.reload_capability).to be_a(Set)
            expect(device.reload_capability).to be_include(Revdev::KEY_ESC)       # 1
            expect(device.reload_capability).to be_include(Revdev::KEY_1)         # 2
            expect(device.reload_capability).to be_include(Revdev::KEY_A)         # 30
            expect(device.reload_capability).to be_include(Revdev::KEY_LEFTSHIFT) # 42
          end
        end
      end
    end
  end
end
