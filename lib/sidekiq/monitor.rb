require 'slim'
require 'jquery-datatables-rails'
require 'ajax-datatables-rails'

directory = File.dirname(File.absolute_path(__FILE__))
Dir.glob("#{directory}/monitor/**/*.rb") { |file| require file }

module Sidekiq
  module Monitor
    def self.table_name_prefix
      'sidekiq_'
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
