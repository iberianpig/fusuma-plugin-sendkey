# frozen_string_literal: true

require_relative '../sendkey/keyboard.rb'

module Fusuma
  module Plugin
    module Executors
      # Control Window or Workspaces by executing wctrl
      class SendkeyExecutor < Executor
        def config_param_types
          {
            'device_path': String
          }
        end

        # execute sendkey command
        # @param event [Event]
        # @return [nil]
        def execute(event)
          MultiLogger.info(sendkey: search_param(event))
          pid = fork do
            Process.daemon(true)
            keyboard.type(param: search_param(event))
          end

          Process.detach(pid)
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
                          device = Sendkey::Device.new(path: config_params(:device_path))
                          Sendkey::Keyboard.new(device: device)
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
