# frozen_string_literal: true

require 'spec_helper'

require './lib/fusuma/plugin/sendkey/keyboard'

module Fusuma
  module Plugin
    module Sendkey
      RSpec.describe Keyboard do
        describe '#new' do
          context 'keyboard is found' do
            before do
              dummy_keyboard = Fusuma::Device.new(name: 'dummy keyboard')
              allow_any_instance_of(Sendkey::Keyboard)
                .to receive(:find_device)
                .and_return(dummy_keyboard)
              allow(Sendkey::Device).to receive(:new).and_return('dummy')
            end

            it 'should not raise error' do
              expect { Keyboard.new }.not_to raise_error
            end
          end

          context 'keyboard is not found' do
            before do
              allow_any_instance_of(Sendkey::Keyboard)
                .to receive(:find_device)
                .and_return(nil)
            end

            it 'should not raise error' do
              expect { Keyboard.new }.to raise_error SystemExit
            end
          end

          context 'detected device name is Keyboard (Capitarized)' do
            before do
              other_device = Fusuma::Device.new(name: 'Keyboard', id: 'dummy')

              allow_any_instance_of(Sendkey::Keyboard)
                .to receive(:find_device)
                .and_return(other_device)
              allow(Sendkey::Device).to receive(:new).and_return('dummy')
            end

            it 'should not raise error' do
              expect { Keyboard.new }.not_to raise_error
            end
          end

          context 'detected device name is KEYBOARD (Upper case)' do
            before do
              other_device = Fusuma::Device.new(name: 'KEYBOARD', id: 'dummy')
              allow_any_instance_of(Sendkey::Keyboard)
                .to receive(:find_device)
                .and_return(other_device)
              allow(Sendkey::Device).to receive(:new).and_return('dummy')
            end

            it 'should not raise error' do
              expect { Keyboard.new }.not_to raise_error
            end
          end

          context 'given name pattern' do
            before do
              specified_device = Fusuma::Device.new(
                name: 'Awesome KEY/BOARD input device',
                id: 'dummy'
              )
              allow(Fusuma::Device).to receive(:all).and_return([specified_device])
              allow(Sendkey::Device).to receive(:new).and_return('dummy')
            end

            it 'should not raise error' do
              expect { Keyboard.new(name_pattern: 'Awesome KEY/BOARD') }.not_to raise_error
            end
          end

          context 'not given name pattern (use default)' do
            subject { -> { Keyboard.new(name_pattern: nil) } }
            before do
              allow(Sendkey::Device).to receive(:new).and_return('dummy')
            end

            context 'exist device named keyboard' do
              before do
                specified_device = Fusuma::Device.new(
                  name: 'keyboard',
                  id: 'dummy'
                )
                allow(Fusuma::Device).to receive(:all).and_return([specified_device])
              end

              it { is_expected.not_to raise_error }
            end

            context 'exist device named Keyboard' do
              before do
                specified_device = Fusuma::Device.new(
                  name: 'Keyboard',
                  id: 'dummy'
                )
                allow(Fusuma::Device).to receive(:all).and_return([specified_device])
              end

              it { is_expected.not_to raise_error }
            end

            context 'exist device named KEYBOARD' do
              before do
                specified_device = Fusuma::Device.new(
                  name: 'KEYBOARD',
                  id: 'dummy'
                )
                allow(Fusuma::Device).to receive(:all).and_return([specified_device])
              end

              it { is_expected.not_to raise_error }
            end

            context 'exist no device named keyboard|Keyboard|KEYBOARD' do
              before do
                specified_device = Fusuma::Device.new(
                  name: 'KEY-BOARD',
                  id: 'dummy'
                )
                allow(Fusuma::Device).to receive(:all).and_return([specified_device])
              end

              it { is_expected.to raise_error(SystemExit) }
            end
          end
        end
      end
    end
  end
end
