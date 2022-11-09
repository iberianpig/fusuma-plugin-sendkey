# frozen_string_literal: true

require_relative '../sendkey/mouse'

module Fusuma
  module Plugin
    module Executors
      # Control Window or Workspaces by executing wctrl
      class SendbuttonExecutor < Executor
        def execute_keys
          %i[sendbutton]
        end

        def config_param_types
          {
            device_name: String
          }
        end

        # fork and execute sendbutton command
        # @param event [Event]
        # @return [nil]
        def execute(event)
          MultiLogger.info(sendbutton: search_param(event))
          pid = fork do
            Process.daemon(true)
            _execute(event)
          end

          Process.detach(pid)
        end

        # execute sendbutton command
        # @param event [Event]
        # @return [nil]
        def _execute(event)
          mouse.click_button(param: search_param(event))
        end

        # check executable
        # @param event [Event]
        # @return [TrueClass, FalseClass]
        def executable?(event)
          event.tag.end_with?('_detector') && event.record.type == :index
          mouse.valid?(param: search_param(event))
        end

        private

        # @return [Sendkey::Mouse]
        def mouse
          @mouse ||= begin
            name_pattren = config_params(:device_mouse_name)
            Sendkey::Mouse.new(name_pattern: name_pattren)
          end
        end

        def search_param(event)
          index = Config::Index.new([*event.record.index.keys, :sendbutton])
          Config.search(index)
        end
      end
    end
  end
end
