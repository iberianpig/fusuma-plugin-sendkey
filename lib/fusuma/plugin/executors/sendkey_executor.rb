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
          return if search_command(event).nil?

          MultiLogger.info(sendkey: search_param(event))
          pid = fork do
            Process.daemon(true)
            exec(search_command(event))
          end

          Process.detach(pid)
        end

        # check executable
        # @param event [Event]
        # @return [TrueClass, FalseClass]
        def executable?(event)
          event.tag.end_with?('_detector') &&
            event.record.type == :index &&
            search_command(event)
        end

        # @param event [Event]
        # @return [String]
        # @return [NilClass]
        def search_command(event)
          @keyboard ||= begin
                          device = Device.new(path: config_params(:device_path))
                          Keyboard.new(device: device)
                        end
          @keyboard.type_command(param: search_param(event))
        end

        private

        def search_param(event)
          index = Config::Index.new([*event.record.index.keys, :sendkey])
          Config.search(index)
        end
      end
    end
  end
end
