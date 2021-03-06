# frozen_string_literal: true

require_relative '../sendkey/keyboard'

module Fusuma
  module Plugin
    module Executors
      # Control Window or Workspaces by executing wctrl
      class SendkeyExecutor < Executor
        def execute_keys
          [:sendkey]
        end

        def config_param_types
          {
            device_name: String
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
          keyboard.type(param: search_param(event))
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
      end
    end
  end
end
