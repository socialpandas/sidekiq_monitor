module Sidekiq
  module Monitor
    module SidekiqHelper
      def app_name
        'Sidekiq Monitor'
      end

      def root_path
        Sidekiq::Monitor::Engine.routes.url_helpers.sidekiq_monitor_path
      end
    end
  end
end
