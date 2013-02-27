module Sidekiq
  module Monitor
    class QueuesController < ActionController::Base
      protect_from_forgery

      layout 'sidekiq/monitor/layouts/application'

      helper Sidekiq::Monitor::SidekiqHelper
      
      def index
        @queues = Job.select('DISTINCT queue').collect { |job| job.queue }.sort
      end
    end
  end
end
