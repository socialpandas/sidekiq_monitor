module Sidekiq
  module Monitor
    class Processor
      def queue(worker_class, item, queue)
        args = item['args']
        name = job_name(worker_class, args)
        Sidekiq::Monitor::Job.find_or_create_by_jid(
          jid: item['jid'],
          queue: queue,
          class_name: worker_class.name,
          args: args,
          retry: item['retry'],
          enqueued_at: DateTime.now,
          status: 'queued',
          name: name
        )
      end

      def start(worker, msg, queue)
        jid = msg['jid']
        args = msg['args']
        now = DateTime.now
        job = Sidekiq::Monitor::Job.find_by_jid(jid)
        if job.blank?
          name = job_name(worker.class, args)
          job = Sidekiq::Monitor::Job.new(
            jid: jid,
            queue: queue,
            class_name: worker.class.name,
            args: args,
            retry: msg['retry'],
            enqueued_at: now,
            name: name
          )
        end
        job.update_attributes(
          started_at: now,
          status: 'running'
        )
      end

      def error(worker, msg, queue, exception)
        result = {
          message: exception.message,
          backtrace: exception.backtrace
        }
        job = find_job(msg)
        return unless job
        job.update_attributes(
          finished_at: DateTime.now,
          status: 'failed',
          result: result
        )
      end

      def complete(worker, msg, queue, return_value)
        job = find_job(msg)
        return unless job
        job.update_attributes(
          finished_at: DateTime.now,
          status: 'complete',
          result: (return_value if return_value.is_a?(Hash))
        )
      end

      protected

      def find_job(msg)
        Sidekiq::Monitor::Job.find_by_jid(msg['jid'])
      end

      def job_name(worker_class, args)
        worker_class.respond_to?(:job_name) ? worker_class.job_name(*args) : nil
      end
    end
  end
end
