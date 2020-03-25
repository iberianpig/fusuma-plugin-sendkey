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

          fusuma_device = double(Fusuma::Device, id: 'eventN')

          allow_any_instance_of(Sendkey::Keyboard).to receive(:find_device)
            .with(name_pattern: 'dummy').and_return fusuma_device

          device = double(Sendkey::Device)

          allow(Sendkey::Device).to receive(:new)
            .with(path: "/dev/input/#{fusuma_device.id}")
            .and_return(device)

          keyboard = Sendkey::Keyboard.new(name_pattern: 'dummy')

          allow(Sendkey::Keyboard).to receive(:new)
            .with(name_pattern: 'dummy').and_return keyboard

          allow(keyboard).to receive(:support?).with('KEY_MODIFIER_CODE').and_return true
          allow(keyboard).to receive(:support?).with('KEY_KEY_CODE').and_return true
          allow(keyboard).to receive(:support?).with('KEY_INVALID_CODE').and_return false
        end

        describe '#execute' do
          it 'fork' do
            allow(Process).to receive(:daemon).with(true)
            allow(Process).to receive(:detach).with(anything)

            expect(@executor).to receive(:fork).and_yield do |block_context|
              allow(block_context).to receive(:search_param).with(@event)

              keyboard = double(Sendkey::Keyboard)
              allow(block_context).to receive(:keyboard).and_return(keyboard)
              allow(keyboard).to receive(:type).with(anything)
            end

            @executor.execute(@event)
          end
        end

        describe '#executable?' do
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
              expect(@executor.executable?(@event)) .to be_truthy
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
