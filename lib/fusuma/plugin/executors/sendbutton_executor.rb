# frozen_string_literal: true

require_relative "../sendkey/mouse"

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
            device_mouse_name: String
          }
        end

        # fork and execute sendbutton command
        # @param event [Event]
        # @return [nil]
        def execute(event)
          MultiLogger.info(sendbutton: extract_status_param(event))
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
          status, _ = extract_status_param(event)
          case status
          when :press
            mouse.press_button(param: search_param(event))
          when :release
            mouse.release_button(param: search_param(event))
          else
            mouse.click_button(param: search_param(event))
          end
        end

        # check executable
        # @param event [Event]
        # @return [TrueClass, FalseClass]
        def executable?(event)
          return false unless event.tag.end_with?("_detector") && event.record.type == :index

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

        # @return [Array<Symbol, String>] Symbol, String
        def extract_status_param(event)
          index = Config::Index.new([*event.record.index.keys, :sendbutton])
          result = Config.search(index)
          case result
          when Hash
            result.find { |k, _| (k == :press) || (k == :release) }
          else
            [nil, result]
          end
        end

        def search_param(event)
          _, status_param = extract_status_param(event)
          status_param
        end
      end
    end
  end
end
