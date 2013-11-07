module Sidekiq
  module Monitor
    class Processor
      def queue(worker_class, item, queue)
        job = find_or_initialize_job(worker_class, item, queue)
        job.save
      end

      def start(worker, item, queue)
        job = find_or_initialize_job(worker, item, queue)
        job.update_attributes(
          started_at: DateTime.now,
          status: 'running'
        )
      end

      def error(worker, item, queue, exception)
        job = find_or_initialize_job(worker, item, queue)
        set_error(job, exception)
      end

      def complete(worker, item, queue, return_value)
        job = find_or_initialize_job(worker, item, queue)
        job.update_attributes(
          finished_at: DateTime.now,
          status: 'complete',
          result: (return_value if return_value.is_a?(Hash))
        )
      end

      protected

      def find_or_initialize_job(worker, item, queue, options={})
        defaults = {
          set_name: true
        }
        options.reverse_merge!(defaults)

        worker_class = nil
        if worker.is_a?(String)
          worker_class = worker.constantize
        elsif worker.is_a?(Class)
          worker_class = worker
        else
          worker_class = worker.class
        end

        job = Sidekiq::Monitor::Job.find_by_jid(item['jid'])
        if job.blank?
          attributes = {
            jid: item['jid'],
            queue: queue,
            class_name: worker_class.name,
            args: item['args'],
            retry: item['retry'],
            enqueued_at: DateTime.now,
            status: 'queued'
          }
          if options[:set_name] == true
            attributes[:name] = job_name(worker_class, item, queue)
          end
          job = Sidekiq::Monitor::Job.new(attributes)
        end
        job
      end

      def job_name(worker_class, item, queue)
        args = item['args']
        begin
          worker_class.respond_to?(:job_name) ? worker_class.job_name(*args) : nil
        rescue Exception => exception
          # If the job doesn't exist yet, we'll need to create it
          job = find_or_initialize_job(worker_class, item, queue, set_name: false)
          set_error(job, exception)
          raise exception
        end
      end

      def set_error(job, exception)
        result = job.result.present? ? job.result.symbolize_keys : {}
        result.merge!({
          message: "#{exception.class.name}: #{exception.message}",
          backtrace: exception.backtrace
        })
        job.update_attributes(
          finished_at: DateTime.now,
          status: 'failed',
          result: result
        )
      end
    end
  end
end
