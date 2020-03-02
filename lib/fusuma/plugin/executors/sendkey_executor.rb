# frozen_string_literal: true

require_relative '../sendkey/keyboard.rb'

module Fusuma
  module Plugin
    module Executors
      # Control Window or Workspaces by executing wctrl
      class SendkeyExecutor < Executor
        # execute sendkey command
        # @param event [Event]
        # @return [nil]
        def execute(event)
          return if search_command(event).nil?

          MultiLogger.info(sendkey: search_command(event))
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
          index = Config::Index.new([*event.record.index.keys, :sendkey])

          param = Config.search(index)

          @keyboard ||= Keyboard.new

          @keyboard.type_command(param: param)
        end
      end
    end
  end
end
