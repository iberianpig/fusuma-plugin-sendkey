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
          it "send KEY_CODE message to keybard" do
            allow(@executor).to receive(:search_param).with(@event).and_return("KEY_CODE")
            allow(@executor).to receive(:search_keypress).with(@event).and_return(nil)
            expect(@keyboard).to receive(:type).with(param: "KEY_CODE", keep: nil)
            @executor._execute(@event)
          end

          context "with keypress" do
            before do
              index_with_keypress = Config::Index.new(
                [:dummy, 1, :direction, :keypress, :LEFTSHIFT]
              )
              record = Events::Records::IndexRecord.new(index: index_with_keypress)
              @event = Events::Event.new(tag: "dummy_detector", record: record)
            end

            it "send KEY_CODE_WITH_KEYPRESS message to keybard" do
              expect(@keyboard).to receive(:type).with(param: "KEY_CODE_WITH_KEYPRESS", keep: "LEFTSHIFT")

              @executor._execute(@event)
            end
          end
        end

        describe "#executable?" do
          before do
            allow(@keyboard).to receive(:valid?).with(param: "MODIFIER_CODE+KEY_CODE")
              .and_return true
            allow(@keyboard).to receive(:valid?).with(param: "KEY_CODE")
              .and_return true
            allow(@keyboard).to receive(:valid?).with(param: "INVALID_CODE")
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
