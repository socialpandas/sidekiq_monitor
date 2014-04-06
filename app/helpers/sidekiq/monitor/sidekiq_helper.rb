module Sidekiq
  module Monitor
    module SidekiqHelper
      def app_name
        'Sidekiq Monitor'
      end

      def root_path
        Sidekiq::Monitor.root_path
      end
    end
  end
end
