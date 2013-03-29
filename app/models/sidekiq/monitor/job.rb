module Sidekiq
  module Monitor
    class Job < ActiveRecord::Base
      attr_accessible :args, :class_name, :enqueued_at, :finished_at, :jid, :name, :queue, :result, :retry, :started_at, :status

      serialize :args
      serialize :result

      STATUSES = [
        'queued',
        'running',
        'complete',
        'failed'
      ]

      def self.destroy_by_queue(queue_name, conditions={})
        jobs = where(conditions).where(status: 'queued', queue: queue_name).destroy_all
        jids = jobs.map(&:jid)
        queue = Sidekiq::Queue.new(queue_name)
        queue.each do |job|
          job.delete if conditions.blank? || jids.include?(job.jid)
        end
        jobs
      end
    end
  end
end
