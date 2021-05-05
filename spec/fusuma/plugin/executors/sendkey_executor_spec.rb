# frozen_string_literal: true

require 'spec_helper'

require 'fusuma/plugin/executors/executor'
require 'fusuma/plugin/events/event'
require 'fusuma/plugin/events/records/index_record'

require './lib/fusuma/plugin/executors/sendkey_executor'

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
          @event = Events::Event.new(tag: 'dummy_detector', record: record)
          @executor = SendkeyExecutor.new

          @keyboard = double(Sendkey::Keyboard)

          allow(@executor).to receive(:keyboard).and_return @keyboard
        end

        describe '#execute' do
          before do
            allow(Process).to receive(:daemon).with(true)
            allow(Process).to receive(:detach).with(anything)
          end
          it 'fork' do
            expect(@executor).to receive(:fork).and_yield do |block_context|
              expect(block_context).to receive(:_execute).with(@event)
            end

            @executor.execute(@event)
          end
        end

        describe '#_execute' do
          after do
            @executor._execute(@event)
          end
          it 'send KEY_CODE message to keybard' do
            expect(@executor).to receive(:search_param).with(@event).and_return('KEY_CODE')
            expect(@keyboard).to receive(:type).with(param: 'KEY_CODE')
          end
        end

        describe '#executable?' do
          before do
            allow(@keyboard).to receive(:valid?).with(param: 'MODIFIER_CODE+KEY_CODE')
                                                .and_return true
            allow(@keyboard).to receive(:valid?).with(param: 'KEY_CODE')
                                                .and_return true
            allow(@keyboard).to receive(:valid?).with(param: 'INVALID_CODE')
                                                .and_return false
          end
          context 'when given valid event tagged as xxxx_detector' do
            it { expect(@executor.executable?(@event)).to be_truthy }
          end

          context 'when given INVALID event tagged as invalid_tag' do
            before do
              @event.tag = 'invalid_tag'
            end
            it { expect(@executor.executable?(@event)).to be_falsey }
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

            it 'should return true' do
              expect(@executor.executable?(@event)).to be_truthy
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
          end
        end
      end
    end
  end
end
