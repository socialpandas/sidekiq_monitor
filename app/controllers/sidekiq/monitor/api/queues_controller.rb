module Sidekiq
  module Monitor
    module Api
      class QueuesController < ActionController::Base
        protect_from_forgery

        def show
          queue = params[:queue]
          render json: {}, status: 404 and return if queue.blank?

          status_counts = Sidekiq::Monitor::Job.where(queue: queue).count(group: 'status')
          ordered_status_counts = {}
          Sidekiq::Monitor::Job.statuses.each do |status|
            ordered_status_counts[status] = status_counts.has_key?(status) ? status_counts[status] : 0
          end
          response = {
            status_counts: ordered_status_counts
          }
          render json: response.to_json, status: :ok
        end
      end
    end
  end
end
