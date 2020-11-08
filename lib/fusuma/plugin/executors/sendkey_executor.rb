# frozen_string_literal: true

require_relative '../sendkey/keyboard.rb'

module Fusuma
  module Plugin
    module Executors
      # Control Window or Workspaces by executing wctrl
      class SendkeyExecutor < Executor
        def config_param_types
          {
            'device_name': String
          }
        end

        # fork and execute sendkey command
        # @param event [Event]
        # @return [nil]
        def execute(event)
          MultiLogger.info(sendkey: search_param(event))
          pid = fork do
            Process.daemon(true)
            _execute(event)
          end

          Process.detach(pid)
        end

        # execute sendkey command
        # @param event [Event]
        # @return [nil]
        def _execute(event)
          keyboard.type(
            param: search_param(event),
            keep: search_keypress(event)
          )
        end

        # check executable
        # @param event [Event]
        # @return [TrueClass, FalseClass]
        def executable?(event)
          event.tag.end_with?('_detector') &&
            event.record.type == :index &&
            keyboard.valid?(param: search_param(event))
        end

        private

        def keyboard
          @keyboard ||= begin
                          name_pattren = config_params(:device_name)
                          Sendkey::Keyboard.new(name_pattern: name_pattren)
                        end
        end

        def search_param(event)
          index = Config::Index.new([*event.record.index.keys, :sendkey])
          Config.search(index)
        end

        # @param event [Event]
        # @return [String]
        def search_keypress(event)
          keys = event.record.index.keys
          keypress_index = keys.find_index { |k| k.symbol == :keypress }
          code = keypress_index && keys[keypress_index + 1].symbol
          code.to_s
        end
      end
    end
  end
end
