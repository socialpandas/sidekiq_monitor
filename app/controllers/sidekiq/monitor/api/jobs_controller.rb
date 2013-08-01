module Sidekiq
  module Monitor
    module Api
      class JobsController < ActionController::Base
        protect_from_forgery

        def index
          render json: JobsDatatable.new(view_context)
        end

        def graph
          queues_jobs = Job.select('queue, status').all.group_by(&:queue)
          queues = []
          statuses = Job.statuses
          queues_status_counts = queues_jobs.collect do |queue, jobs|
            statuses_jobs = jobs.group_by(&:status)
            statuses_job_counts = statuses_jobs.collect do |status, jobs|
              next unless statuses.include?(status)
              [status, jobs.length]
            end
            statuses_job_counts = Hash[statuses_job_counts.compact]
            queues << queue unless queues.include?(queue)
            { queue: queue }.merge(statuses_job_counts)
          end
          queues_status_counts = queues_status_counts.sort_by { |q| q[:queue] }
          render json: {
            queues_status_counts: queues_status_counts,
            statuses: statuses
          }
        end

        def custom_views
          job = Job.find(params[:id])
          render json: {}, status: 404 and return if job.blank?

          views = CustomViews.for_job(job)
          views = views.collect do |view|
            {
              name: view[:name],
              html: render_to_string(view[:path], locals: {job: job, path: view[:path]})
            }
          end
          render json: views, status: :ok
        end

        def retry
          id = params[:id]
          render json: {}, status: 404 and return if id.blank?

          job = Job.find(id)
          render json: {}, status: 404 and return if job.blank?

          args = job.args
          worker = job.class_name.constantize
          worker.perform_async(*args)
          render json: {}, status: :ok
        end

        def clean
          cleaner = Sidekiq::Monitor::Cleaner.new
          cleaner.clean
          render json: {}, status: :ok
        end

        def statuses
          render json: Sidekiq::Monitor::Job.statuses, status: :ok
        end
      end
    end
  end
end
