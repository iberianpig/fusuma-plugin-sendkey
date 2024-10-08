# frozen_string_literal: true

require "spec_helper"

require "fusuma/plugin/executors/executor"
require "fusuma/plugin/events/event"
require "fusuma/plugin/events/records/index_record"

require "./lib/fusuma/plugin/executors/sendkey_executor"

module Fusuma
  module Plugin
    module Executors
      RSpec.describe SendkeyExecutor do
        around do |example|
          ConfigHelper.load_config_yml = <<~CONFIG
            dummy:
              1:
                direction:
                  sendkey: KEY_CODE
                  keypress:
                    LEFTSHIFT:
                      sendkey: KEY_CODE_WITH_KEYPRESS
                    LEFTALT:
                      sendkey: KEY_CODE_WITH_KEYPRESS_WITH_CLEAR
                      clearmodifiers: true

                direction2: { sendkey: ["LEFTSHIFT+F10", "T", "ENTER", "ESC"] }

            plugin:
              executors:
                sendkey_executor:
                  device_name: dummy
          CONFIG

          example.run

          Config.custom_path = nil
        end

        before do
          index = Config::Index.new([:dummy, 1, :direction])
          record = Events::Records::IndexRecord.new(index: index)
          @event = Events::Event.new(tag: "dummy_detector", record: record)
          @executor = SendkeyExecutor.new

          @keyboard = instance_double(Sendkey::Keyboard)

          allow(@executor).to receive(:keyboard).and_return @keyboard
        end

        describe "#execute" do
          subject { @executor.execute(@event) }
          it "send KEY_CODE message to keyboard" do
            expect(@keyboard).to receive(:type).with(param: "KEY_CODE", keep: "", clear: :none)
            subject
          end

          context "with keypress" do
            before do
              index_with_keypress = Config::Index.new([:dummy, 1, :direction, :keypress, :LEFTSHIFT])
              record = Events::Records::IndexRecord.new(index: index_with_keypress)
              @event = Events::Event.new(tag: "dummy_detector", record: record)
            end

            it "send KEY_CODE_WITH_KEYPRESS message to keyboard" do
              expect(@keyboard).to receive(:type).with(param: "KEY_CODE_WITH_KEYPRESS", keep: "LEFTSHIFT", clear: :none)
              subject
            end
            context "with clearmodifiers" do
              before do
                index_with_keypress = Config::Index.new([:dummy, 1, :direction, :keypress, :LEFTALT])
                record = Events::Records::IndexRecord.new(index: index_with_keypress)
                @event = Events::Event.new(tag: "dummy_detector", record: record)
              end

              it "send KEY_CODE_WITH_KEYPRESS_WITH_CLEAR message to keyboard" do
                expect(@keyboard).to receive(:type).with(param: "KEY_CODE_WITH_KEYPRESS_WITH_CLEAR", keep: "LEFTALT", clear: true)
                subject
              end
            end
          end

          context "with multiple keys from sendkey array" do
            before do
              index_with_array = Config::Index.new([:dummy, 1, :direction2])
              record = Events::Records::IndexRecord.new(index: index_with_array)
              @event = Events::Event.new(tag: "dummy_detector", record: record)
            end

            it "sends each key from the sendkey array to keyboard" do
              expect(@keyboard).to receive(:types).with(["LEFTSHIFT+F10", "T", "ENTER", "ESC"])
              subject
            end
          end
        end

        describe "#executable?" do
          before do
            allow(@keyboard).to receive(:valid?).with("MODIFIER_CODE+KEY_CODE")
              .and_return true
            allow(@keyboard).to receive(:valid?).with("KEY_CODE")
              .and_return true
            allow(@keyboard).to receive(:valid?).with("INVALID_CODE")
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

          context "when sendkey: 'MODIFIER_CODE+KEY_CODE'" do
            around do |example|
              ConfigHelper.load_config_yml = <<~CONFIG
                dummy:
                  1:
                    direction:
                      sendkey: 'MODIFIER_CODE+KEY_CODE'
                plugin:
                  executors:
                    sendkey_executor:
                      device_name: dummy
              CONFIG

              example.run

              Config.custom_path = nil
            end

            it "returns true" do
              expect(@executor).to be_executable(@event)
            end
          end

          context "when sendkey: 'INVALID_CODE'" do
            around do |example|
              ConfigHelper.load_config_yml = <<~CONFIG
                dummy:
                  1:
                    direction:
                      sendkey: 'INVALID_CODE'
                plugin:
                  executors:
                    sendkey_executor:
                      device_name: dummy
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
