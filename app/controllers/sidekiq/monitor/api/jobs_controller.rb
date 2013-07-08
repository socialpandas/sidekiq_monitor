module Sidekiq
  module Monitor
    module Api
      class JobsController < ActionController::Base
        protect_from_forgery

        def index
          render json: JobsDatatable.new(view_context)
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
          jid = params[:jid]
          render json: {}, status: 404 and return if jid.blank?

          job = Job.find_by_jid(jid)
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
      end
    end
  end
end
