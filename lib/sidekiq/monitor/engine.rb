module Sidekiq
  module Monitor
    class Engine < ::Rails::Engine
      isolate_namespace Monitor

      initializer "sidekiq_monitor.asset_pipeline" do |app|
        app.config.assets.precompile << 'sidekiq/monitor/application.js'
      end
    end
  end
end
