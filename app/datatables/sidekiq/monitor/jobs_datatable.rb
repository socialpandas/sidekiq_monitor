module Sidekiq
  module Monitor
    class JobsDatatable < AjaxDatatablesRails
      include ActionView::Helpers::DateHelper

      def initialize(view)
        @model_name = Sidekiq::Monitor::Job
        @columns = [
          'sidekiq_jobs.id',
          'sidekiq_jobs.jid',
          'sidekiq_jobs.queue',
          'sidekiq_jobs.class_name',
          'sidekiq_jobs.name',
          'sidekiq_jobs.enqueued_at',
          'sidekiq_jobs.started_at',
          'COALESCE(sidekiq_jobs.finished_at, NOW()) - sidekiq_jobs.started_at',
          'sidekiq_jobs.status',
          'sidekiq_jobs.result',
          'sidekiq_jobs.args'
        ]
        @searchable_columns = [
          'sidekiq_jobs.jid',
          'sidekiq_jobs.queue',
          'sidekiq_jobs.class_name',
          'sidekiq_jobs.args',
          'sidekiq_jobs.status',
          'sidekiq_jobs.name'
        ]
        super(view)
      end
      
      private

      def data
        jobs.map do |job|
          [
            job.id,
            job.jid,
            job.queue,
            job.class_name,
            job.name || job.args.to_s,
            job.enqueued_at,
            job.started_at,
            get_duration(job),
            job.result.blank? ? nil : job.result[:message],
            job.status,
            job.result,
            job.args
          ]
        end
      end

      def jobs
        @jobs ||= fetch_records
      end

      def get_raw_records
        records = Sidekiq::Monitor::Job
        records = records.where(queue: params[:queue]) unless params[:queue].blank?
        records
      end

      def get_duration(job)
        if job.started_at
          to_time = job.finished_at ? job.finished_at : Time.now
          return simplified_distance_of_time_in_words(job.started_at, to_time)
        end
        nil
      end

      def simplified_distance_of_time_in_words(from_time, to_time)
        distance_of_time_in_words(from_time, to_time, true).gsub('less than ', '').gsub('about ', '')
      end
    end
  end
end
