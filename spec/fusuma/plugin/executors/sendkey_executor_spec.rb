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
        before do
          index = Config::Index.new([:dummy, 1, :direction])
          record = Events::Records::IndexRecord.new(index: index)
          @event = Events::Event.new(tag: 'dummy_detector', record: record)
          @executor = SendkeyExecutor.new
        end

        around do |example|
          ConfigHelper.load_config_yml = <<~CONFIG
            dummy:
              1:
                direction:
                  sendkey: A
          CONFIG

          example.run

          Config.custom_path = nil
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
          context "when sendkey: 'LEFTALT+LEFT'" do
            around do |example|
              ConfigHelper.load_config_yml = <<~CONFIG
                dummy:
                  1:
                    direction:
                      sendkey: 'LEFTALT+LEFT'
              CONFIG

              example.run

              Config.custom_path = nil
            end

            it 'should return evemu-event command' do
              expect(@executor.search_command(@event))
                .to match(/evemu-event\s.+KEY_LEFTALT.+LEFT/)
            end
          end

          context "when sendkey: 'INVALID_KEY'" do
            around do |example|
              ConfigHelper.load_config_yml = <<~CONFIG
                dummy:
                  1:
                    direction:
                      sendkey: 'INVALID_KEY'
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
