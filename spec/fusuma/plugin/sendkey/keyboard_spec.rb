# frozen_string_literal: true

require "spec_helper"

require "./lib/fusuma/plugin/sendkey/keyboard"

module Fusuma
  module Plugin
    module Sendkey
      RSpec.describe Keyboard do
        describe ".find_device" do
          let(:name_patterns) { "keyboard" }
          let(:dummy_device) { instance_double(Device) }

          before do
            allow(Fusuma::Device).to receive(:reset)
          end

          context "when keyboard is found" do
            before do
              dummy_keyboard = Fusuma::Device.new(id: "dummy", name: "dummy keyboard", capabilities: "keyboard")
              allow(Fusuma::Device).to receive(:all).and_return([dummy_keyboard])
              allow(Sendkey::Device).to receive(:new).with(path: "/dev/input/dummy").and_return(dummy_device)
            end

            it { expect(Keyboard.find_device(name_patterns: name_patterns)).to eq dummy_device }
          end

          context "when keyboard is not found" do
            before do
              allow(Fusuma::Device).to receive(:all).and_return([])
            end

            it { expect { Keyboard.find_device(name_patterns: name_patterns) }.to raise_error(SystemExit) }
          end

          context "with multiple name patterns" do
            let(:name_patterns) { ["foobar", "KEY/BOARD"] }

            before do
              specified_device = Fusuma::Device.new(
                name: "Awesome KEY/BOARD input device",
                id: "dummy",
                capabilities: "keyboard"
              )
              allow(Fusuma::Device).to receive(:all).and_return([specified_device])
              allow(Sendkey::Device).to receive(:new).with(path: "/dev/input/dummy").and_return(dummy_device)
            end

            it { expect(Keyboard.find_device(name_patterns: name_patterns)).to eq dummy_device }
          end
        end

        describe "#new" do
          subject { Keyboard.new(device: device) }
          let(:device) { instance_double(Sendkey::Device) }
        end

        describe "#type" do
          subject { @keyboard.type(param: @keys, keep: @keep, clear: @clear) }

          before do
            allow(Keyboard)
              .to receive(:find_device)
              .and_return(Fusuma::Device.new(name: "dummy keyboard"))

            @device = instance_double(Sendkey::Device)
            allow(@device).to receive(:write_event).with(anything)

            allow(Sendkey::Device).to receive(:new).and_return(@device)

            @keyboard = Keyboard.new(device: @device)
            @keys = ""
            @keep = ""
            @clear = :none
          end

          it "presses key KEY_A and release KEY_A" do
            @keys = "A"
            expect(@keyboard).to receive(:clear_modifiers).ordered
            expect(@keyboard).to receive(:send_event).with(code: "KEY_A", press: true).ordered
            expect(@keyboard).to receive(:send_event).with(code: "KEY_A", press: false).ordered
            subject
          end

          context "with mouse button" do
            before do
              @keys = "BTN_LEFT"
            end

            it "presses button BTN_LEFT and release button BTN_LEFT" do
              expect(@keyboard).to receive(:clear_modifiers).ordered
              expect(@keyboard).to receive(:send_event).with(code: "BTN_LEFT", press: true).ordered
              expect(@keyboard).to receive(:send_event).with(code: "BTN_LEFT", press: false).ordered
              subject
            end

            context "with modifier keys" do
              before do
                @keys = "LEFTSHIFT+BTN_LEFT"
              end

              it "types (Shift)BTN_LEFT" do
                expect(@keyboard).to receive(:clear_modifiers).with([]).ordered
                expect(@keyboard).to receive(:send_event).with(code: "KEY_LEFTSHIFT", press: true).ordered
                expect(@keyboard).to receive(:send_event).with(code: "BTN_LEFT", press: true).ordered
                expect(@keyboard).to receive(:send_event).with(code: "BTN_LEFT", press: false).ordered
                expect(@keyboard).to receive(:send_event).with(code: "KEY_LEFTSHIFT", press: false).ordered
                subject
              end
            end
          end

          context "with modifier keys" do
            before do
              @keys = "LEFTSHIFT+A"
            end

            it "types (Shift)A" do
              expect(@keyboard).to receive(:clear_modifiers).with([]).ordered
              expect(@keyboard).to receive(:send_event).with(code: "KEY_LEFTSHIFT", press: true).ordered
              expect(@keyboard).to receive(:send_event).with(code: "KEY_A", press: true).ordered
              expect(@keyboard).to receive(:send_event).with(code: "KEY_A", press: false).ordered
              expect(@keyboard).to receive(:send_event).with(code: "KEY_LEFTSHIFT", press: false).ordered
              subject
            end

            context "with keep option" do
              before do
                @keep = "LEFTSHIFT"
              end
              it "types (Shift)A and skip press and release LEFTSHIFT" do
                expect(@keyboard).to receive(:clear_modifiers).with([]).ordered
                expect(@keyboard).to receive(:send_event).with(code: "KEY_A", press: true).ordered
                expect(@keyboard).to receive(:send_event).with(code: "KEY_A", press: false).ordered
                subject
              end

              context "with clear option" do
                before do
                  @clear = true
                end

                it "clear modifiers without LEFTSHIFT" do
                  expect(@keyboard).to receive(:clear_modifiers).with(Keyboard::MODIFIER_KEY_CODES - ["KEY_LEFTSHIFT"]).ordered
                  expect(@keyboard).to receive(:send_event).with(code: "KEY_A", press: true).ordered
                  expect(@keyboard).to receive(:send_event).with(code: "KEY_A", press: false).ordered
                  subject
                end
              end
            end

            context "with clear option" do
              before do
                @clear = true
              end

              it "clear modifiers without LEFTSHIFT" do
                expect(@keyboard).to receive(:clear_modifiers).with(Keyboard::MODIFIER_KEY_CODES - ["KEY_LEFTSHIFT"]).ordered
                expect(@keyboard).to receive(:send_event).with(code: "KEY_LEFTSHIFT", press: true).ordered
                expect(@keyboard).to receive(:send_event).with(code: "KEY_A", press: true).ordered
                expect(@keyboard).to receive(:send_event).with(code: "KEY_A", press: false).ordered
                expect(@keyboard).to receive(:send_event).with(code: "KEY_LEFTSHIFT", press: false).ordered
                subject
              end
            end
          end

          context "with multiple keys" do
            before do
              @keys = "A+B"
            end

            it "types AB" do
              expect(@keyboard).to receive(:clear_modifiers).ordered
              expect(@keyboard).to receive(:send_event).with(code: "KEY_A", press: true).ordered
              expect(@keyboard).to receive(:send_event).with(code: "KEY_B", press: true).ordered
              expect(@keyboard).to receive(:send_event).with(code: "KEY_B", press: false).ordered
              expect(@keyboard).to receive(:send_event).with(code: "KEY_A", press: false).ordered
              subject
            end
          end

          context "with keep(keypress) option" do
            context "when keypress modifier key contains a sendkey parameter" do
              before do
                @keep = "LEFTMETA"
                @keys = "LEFTMETA+LEFT"
              end

              it "sends KEY_LEFT (without clearng or sending KEY_LEFTMETA which pressing by user)" do
                expect(@keyboard).to receive(:clear_modifiers).with([]).ordered
                expect(@keyboard).to receive(:keydown).with("KEY_LEFT").ordered
                expect(@keyboard).to receive(:keyup).with("KEY_LEFT").ordered
                subject
              end

              context "with clear option" do
                before do
                  @clear = true
                end
                it "clear modifiers without LEFTMETA" do
                  expect(@keyboard).to receive(:clear_modifiers).with(Keyboard::MODIFIER_KEY_CODES - ["KEY_LEFTMETA"]).ordered
                  expect(@keyboard).to receive(:keydown).with("KEY_LEFT").ordered
                  expect(@keyboard).to receive(:keyup).with("KEY_LEFT").ordered
                  subject
                end
              end
            end

            context "when keypress modifier key does NOT contains a sendkey parameter" do
              before do
                @keep = "LEFTALT"
                @keys = "BRIGHTNESSUP"
              end

              it "sends KEY_BRIGHTNESSUP (and clear KEY_LEFTALT pressing by user)" do
                expect(@keyboard).to receive(:keydown).with("KEY_BRIGHTNESSUP").ordered
                expect(@keyboard).to receive(:keyup).with("KEY_BRIGHTNESSUP").ordered
                subject
              end

              context "with clear option" do
                before do
                  @clear = true
                end
                it "clear modifiers without LEFTALT" do
                  expect(@keyboard).to receive(:clear_modifiers).with(array_including("KEY_LEFTALT")).ordered
                  expect(@keyboard).to receive(:keydown).with("KEY_BRIGHTNESSUP").ordered
                  expect(@keyboard).to receive(:keyup).with("KEY_BRIGHTNESSUP").ordered
                  subject
                end
              end
            end
          end
        end

        describe "#types" do
          subject { @keyboard.types(@args) }
          context "with multiple keys(Array)" do
            before do
              allow(Keyboard)
                .to receive(:find_device)
                .and_return(Fusuma::Device.new(name: "dummy keyboard"))

              @device = instance_double(Sendkey::Device)
              allow(@device).to receive(:write_event).with(anything)

              allow(Sendkey::Device).to receive(:new).and_return(@device)

              @keyboard = Keyboard.new(device: @device)
              @args = ["LEFTSHIFT+F10", "T", "ENTER", "ESC"]
            end

            it "types LEFTSHIFT+F10, T, ENTER, ESC" do
              expect(@keyboard).to receive(:send_event).with(code: "KEY_LEFTSHIFT", press: true).ordered
              expect(@keyboard).to receive(:send_event).with(code: "KEY_F10", press: true).ordered
              expect(@keyboard).to receive(:send_event).with(code: "KEY_F10", press: false).ordered
              expect(@keyboard).to receive(:send_event).with(code: "KEY_LEFTSHIFT", press: false).ordered
              expect(@keyboard).to receive(:send_event).with(code: "KEY_T", press: true).ordered
              expect(@keyboard).to receive(:send_event).with(code: "KEY_T", press: false).ordered
              expect(@keyboard).to receive(:send_event).with(code: "KEY_ENTER", press: true).ordered
              expect(@keyboard).to receive(:send_event).with(code: "KEY_ENTER", press: false).ordered
              expect(@keyboard).to receive(:send_event).with(code: "KEY_ESC", press: true).ordered
              expect(@keyboard).to receive(:send_event).with(code: "KEY_ESC", press: false).ordered
              subject
            end
          end
        end
      end
    end
  end
end
