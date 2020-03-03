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
          @dummy_device_path = Tempfile.create.path
          ConfigHelper.load_config_yml = <<~CONFIG
            dummy:
              1:
                direction:
                  sendkey: KEY_CODE

            plugin:
              executors:
                sendkey_executor:
                  device_path: #{@dummy_device_path}
          CONFIG

          example.run

          Config.custom_path = nil
        end

        before do
          index = Config::Index.new([:dummy, 1, :direction])
          record = Events::Records::IndexRecord.new(index: index)
          @event = Events::Event.new(tag: 'dummy_detector', record: record)
          @executor = SendkeyExecutor.new

          device = Device.new(path: @dummy_device_path)
          allow(device).to receive(:support?).with('MODIFIER_CODE').and_return true
          allow(device).to receive(:support?).with('KEY_CODE').and_return true
          allow(device).to receive(:support?).with('INVALID_CODE').and_return false
          allow(Device).to receive(:new).with(path: @dummy_device_path).and_return device
        end

        describe '#execute' do
          it 'fork' do
            allow(Process).to receive(:daemon).with(true)
            allow(Process).to receive(:detach).with(anything)

            expect(@executor).to receive(:fork).and_yield do |block_context|
              allow(block_context).to receive(:search_command).with(@event)
              expect(block_context).to receive(:exec).with(anything)
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
        end

        describe '#search_command' do
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
                      device_path: #{@dummy_device_path}
              CONFIG

              example.run

              Config.custom_path = nil
            end

            it 'should return evemu-event command' do
              expect(@executor.search_command(@event))
                .to match(/evemu-event\s.+MODIFIER_CODE.+KEY_CODE./)
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
                      device_path: #{@dummy_device_path}
              CONFIG

              example.run

              Config.custom_path = nil
            end

            it 'should exit' do
              expect { @executor.search_command(@event) }.to raise_error(SystemExit)
            end
          end
        end
      end
    end
  end
end
