# frozen_string_literal: true

require "spec_helper"

require "./lib/fusuma/plugin/sendkey/keyboard"

module Fusuma
  module Plugin
    module Sendkey
      RSpec.describe Keyboard do
        describe "#new" do
          context "when keyboard is found" do
            before do
              dummy_keyboard = Fusuma::Device.new(name: "dummy keyboard")
              allow(Keyboard)
                .to receive(:find_device)
                .and_return(dummy_keyboard)
              allow(Sendkey::Device).to receive(:new).and_return("dummy")
            end

            it "does not raise error" do
              expect { Keyboard.new }.not_to raise_error
            end
          end

          context "when keyboard is not found" do
            before do
              allow(Keyboard)
                .to receive(:find_device)
                .and_return(nil)
            end

            it "does not raise error" do
              expect { Keyboard.new }.to raise_error SystemExit
            end
          end

          context "when detected device name is Keyboard (Capitarized)" do
            before do
              other_device = Fusuma::Device.new(name: "Keyboard", id: "dummy")

              allow(Keyboard)
                .to receive(:find_device)
                .and_return(other_device)
              allow(Sendkey::Device).to receive(:new).and_return("dummy")
            end

            it "does not raise error" do
              expect { Keyboard.new }.not_to raise_error
            end
          end

          context "when detected device name is KEYBOARD (Upper case)" do
            before do
              other_device = Fusuma::Device.new(name: "KEYBOARD", id: "dummy")
              allow(Keyboard)
                .to receive(:find_device)
                .and_return(other_device)
              allow(Sendkey::Device).to receive(:new).and_return("dummy")
            end

            it "does not raise error" do
              expect { Keyboard.new }.not_to raise_error
            end
          end

          context "with given name pattern" do
            before do
              specified_device = Fusuma::Device.new(
                name: "Awesome KEY/BOARD input device",
                id: "dummy"
              )
              allow(Fusuma::Device).to receive(:all).and_return([specified_device])
              allow(Sendkey::Device).to receive(:new).and_return("dummy")
            end

            it "does not raise error" do
              expect { Keyboard.new(name_pattern: "Awesome KEY/BOARD") }.not_to raise_error
            end
          end

          context "when name pattern (use default) is not given" do
            subject { -> { Keyboard.new(name_pattern: nil) } }

            before do
              allow(Sendkey::Device).to receive(:new).and_return("dummy")
            end

            context "when exist device named keyboard(lower-case)" do
              before do
                specified_device = Fusuma::Device.new(
                  name: "keyboard",
                  id: "dummy"
                )
                allow(Fusuma::Device).to receive(:all).and_return([specified_device])
              end

              it { is_expected.not_to raise_error }
            end

            context "when exist device named Keyboard(Capital-case)" do
              before do
                specified_device = Fusuma::Device.new(
                  name: "Keyboard",
                  id: "dummy"
                )
                allow(Fusuma::Device).to receive(:all).and_return([specified_device])
              end

              it { is_expected.not_to raise_error }
            end

            context "when exist device named KEYBOARD(UPPER case)" do
              before do
                specified_device = Fusuma::Device.new(
                  name: "KEYBOARD",
                  id: "dummy"
                )
                allow(Fusuma::Device).to receive(:all).and_return([specified_device])
              end

              it { is_expected.not_to raise_error }
            end

            context "when exist no device named keyboard|Keyboard|KEYBOARD" do
              before do
                specified_device = Fusuma::Device.new(
                  name: "KEY-BOARD",
                  id: "dummy"
                )
                allow(Fusuma::Device).to receive(:all).and_return([specified_device])
              end

              it { is_expected.to raise_error(SystemExit) }
            end
          end
        end

        describe "#type" do
          before do
            allow(Keyboard)
              .to receive(:find_device)
              .and_return(Fusuma::Device.new(name: "dummy keyboard"))

            @device = instance_double(Sendkey::Device)
            allow(@device).to receive(:write_event).with(anything)
            # allow(@device).to receive(:valid?).with(param: 'KEY_A')

            allow(Sendkey::Device).to receive(:new).and_return(@device)

            @keyboard = Keyboard.new
          end

          it "presses key KEY_A and release KEY_A" do
            expect(@keyboard).to receive(:clear_modifiers).ordered
            expect(@keyboard).to receive(:send_event).with(code: "KEY_A", press: true).ordered
            expect(@keyboard).to receive(:send_event).with(code: "KEY_A", press: false).ordered
            @keyboard.type(param: "A")
          end

          context "with modifier keys" do
            before do
              @keys = "LEFTSHIFT+A"
            end

            it "clear all modifier keys except parameter of sendkey" do
              expect(@keyboard).to receive(:clear_modifiers).with(Keyboard::MODIFIER_KEY_CODES - ["KEY_LEFTSHIFT"]).ordered
              @keyboard.type(param: @keys)
            end

            it "types (Shift)A" do
              expect(@keyboard).to receive(:clear_modifiers).ordered
              expect(@keyboard).to receive(:send_event).with(code: "KEY_LEFTSHIFT", press: true).ordered
              expect(@keyboard).to receive(:send_event).with(code: "KEY_A", press: true).ordered
              expect(@keyboard).to receive(:send_event).with(code: "KEY_A", press: false).ordered
              expect(@keyboard).to receive(:send_event).with(code: "KEY_LEFTSHIFT", press: false).ordered
              @keyboard.type(param: @keys)
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
              @keyboard.type(param: @keys)
            end
          end
        end
      end
    end
  end
end
