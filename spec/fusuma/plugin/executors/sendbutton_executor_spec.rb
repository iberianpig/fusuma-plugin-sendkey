# frozen_string_literal: true

require "spec_helper"

require "fusuma/plugin/executors/executor"
require "fusuma/plugin/events/event"
require "fusuma/plugin/events/records/index_record"

require "./lib/fusuma/plugin/executors/sendbutton_executor"

module Fusuma
  module Plugin
    module Executors
      RSpec.describe SendbuttonExecutor do
        around do |example|
          ConfigHelper.load_config_yml = <<~CONFIG
            dummy:
              1:
                direction:
                  sendbutton: BUTTON_CODE
                direction2:
                  begin:
                    sendbutton:
                      press:
                        BUTTON_CODE_BEGIN
                  end:
                    sendbutton:
                      release:
                        BUTTON_CODE_END

            plugin:
              executors:
                sendbutton_executor:
                  device_mouse_name: dummy
          CONFIG

          example.run

          Config.custom_path = nil
        end

        def event_generator(direction:, status: nil)
          index = Config::Index.new([:dummy, 1, direction, status].compact)
          record = Events::Records::IndexRecord.new(index: index)
          Events::Event.new(tag: "dummy_detector", record: record)
        end

        before do
          @executor = SendbuttonExecutor.new

          @mouse = instance_double(Sendkey::Mouse)

          allow(@executor).to receive(:mouse).and_return @mouse
          @event = event_generator(direction: :direction)
        end

        describe "#execute" do
          before do
            allow(Process).to receive(:daemon).with(true)
            allow(Process).to receive(:detach).with(anything)
          end

          it "fork" do
            expect(@executor).to receive(:fork).and_yield do |block_context|
              expect(block_context).to receive(:_execute).with(@event)
            end

            @executor.execute(@event)
          end
        end

        describe "#_execute" do
          it "send BUTTON_CODE message to mouse" do
            allow(@executor).to receive(:search_param).with(@event).and_return("BUTTON_CODE")
            expect(@mouse).to receive(:click_button).with(param: "BUTTON_CODE")
            @executor._execute(@event)
          end

          context "when gesture begins" do
            before do
              @event = event_generator(direction: :direction2, status: :begin)
            end
            it "press button" do
              expect(@mouse).to receive(:press_button).with(param: "BUTTON_CODE_BEGIN")
              @executor._execute(@event)
            end
          end
          context "when gesture ends" do
            before do
              @event = event_generator(direction: :direction2, status: :end)
            end
            it "press button" do
              expect(@mouse).to receive(:release_button).with(param: "BUTTON_CODE_END")
              @executor._execute(@event)
            end
          end
        end

        describe "#executable?" do
          before do
            allow(@mouse).to receive(:valid?).with(param: "BUTTON_CODE")
              .and_return true
            allow(@mouse).to receive(:valid?).with(param: "INVALID_CODE")
              .and_return false
          end

          context "when given valid event tagged as xxxx_detector" do
            it { expect(@executor).to be_executable(@event) }
          end

          context "when given INVALID event tagged as invalid_tag" do
            before do
              @event.tag = "invalid_tag"
            end

            it { expect(@executor).not_to be_executable(@event) }
          end

          context "when sendbutton: 'INVALID_CODE'" do
            around do |example|
              ConfigHelper.load_config_yml = <<~CONFIG
                dummy:
                  1:
                    direction:
                      sendbutton: 'INVALID_CODE'
                plugin:
                  executors:
                    sendkey_executor:
                      device_mouse_name: dummy
              CONFIG

              example.run

              Config.custom_path = nil
            end

            it "returns true" do
              expect(@executor).not_to be_executable(@event)
            end
          end
        end
      end
    end
  end
end
