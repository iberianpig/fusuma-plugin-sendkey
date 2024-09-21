# frozen_string_literal: true

require_relative "../sendkey/keyboard"

module Fusuma
  module Plugin
    module Executors
      # Execute to send key event to device
      class SendkeyExecutor < Executor
        def initialize
          @device_name = config_params(:device_name)
          super
        end

        def execute_keys
          [:sendkey]
        end

        def config_param_types
          {
            device_name: [String, Array]
          }
        end

        # fork and execute sendkey command
        # @param event [Event]
        # @return [nil]
        def execute(event)
          params = search_param(event)
          MultiLogger.info(sendkey: params)
          case params
          when Array
            keyboard.types(params)
          when String
            keyboard.type(
              param: params,
              keep: search_keypress(event),
              clear: clearmodifiers(event)
            )
          else
            MultiLogger.error("sendkey: Invalid config: #{params}")
            nil
          end
        end

        # check executable
        # @param event [Event]
        # @return [TrueClass, FalseClass]
        def executable?(event)
          event.tag.end_with?("_detector") &&
            event.record.type == :index &&
            keyboard.valid?(search_param(event))
        end

        private

        def keyboard
          @keyboard ||= Sendkey::Keyboard.new(name_pattern: @device_name)
        end

        def search_param(event)
          index = Config::Index.new([*event.record.index.keys, :sendkey])
          Config.search(index)
        end

        # search keypress from config for keep modifiers when sendkey
        # @param event [Event]
        # @return [String]
        def search_keypress(event)
          # if fusuma_virtual_keyboard exists, don't have to keep modifiers
          return "" if @device_name == "fusuma_virtual_keyboard"

          keys = event.record.index.keys
          keypress_index = keys.find_index { |k| k.symbol == :keypress }
          code = keypress_index && keys[keypress_index + 1].symbol
          code.to_s
        end

        # clearmodifiers from config
        # @param event [Event]
        # @return [String, TrueClass, Symbole]
        def clearmodifiers(event)
          @clearmodifiers ||= {}
          index = event.record.index
          @clearmodifiers[index.cache_key] ||=
            Config.search(Config::Index.new([*index.keys, "clearmodifiers"])) || :none
        end
      end
    end
  end
end
