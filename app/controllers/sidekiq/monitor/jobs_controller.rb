module Sidekiq
  module Monitor
    class JobsController < ActionController::Base
      protect_from_forgery

      layout 'sidekiq/monitor/layouts/application'

      helper Sidekiq::Monitor::SidekiqHelper
      
      def index
      end

      def graph
      end
    end
  end
end
