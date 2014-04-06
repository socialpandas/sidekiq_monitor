require 'slim'
require 'jquery-datatables-rails'
require 'ajax-datatables-rails'

directory = File.dirname(File.absolute_path(__FILE__))
Dir.glob("#{directory}/monitor/**/*.rb") { |file| require file }
# Require JobsDatatable to expose JobsDatatable.add_search_filter
Dir.glob("#{directory}/../../app/datatables/sidekiq/monitor/jobs_datatable.rb") { |file| require file }

module Sidekiq
  module Monitor
    DEFAULTS = {
      :graphs => nil,
      :javascripts => [],
      :poll_interval => 3000
    }

    def self.options
      @options ||= DEFAULTS.dup
    end

    def self.options=(opts)
      @options = opts
    end

    def self.table_name_prefix
      'sidekiq_'
    end

    def self.root_path
      sidekiq_monitor_path = Sidekiq::Monitor::Engine.routes.url_helpers.sidekiq_monitor_path
      "#{::Rails.application.config.relative_url_root}#{sidekiq_monitor_path}"
    end
  end
end

Sidekiq.configure_client do |config|
  config.client_middleware do |chain|
    chain.add Sidekiq::Monitor::Client::Middleware
  end
end
Sidekiq.configure_server do |config|
  config.client_middleware do |chain|
    chain.add Sidekiq::Monitor::Client::Middleware
  end
  config.server_middleware do |chain|
    chain.add Sidekiq::Monitor::Server::Middleware
  end
end
