module Sidekiq
  module Monitor
    class Job < ActiveRecord::Base
      attr_accessible :args, :class_name, :enqueued_at, :finished_at, :jid, :name, :queue, :result, :retry, :started_at, :status

      serialize :args
      serialize :result

      after_destroy :destroy_in_queue

      STATUSES = [
        'queued',
        'running',
        'complete',
        'failed'
      ]

      def destroy_in_queue
        return true unless status == 'queued'
        sidekiq_queue = Sidekiq::Queue.new(queue)
        sidekiq_queue.each do |job|
          return job.delete if job.jid == jid
        end
      end

      def self.destroy_by_queue(queue, conditions={})
        jobs = where(conditions).where(status: 'queued', queue: queue).destroy_all
        jids = jobs.map(&:jid)
        sidekiq_queue = Sidekiq::Queue.new(queue)
        sidekiq_queue.each do |job|
          job.delete if conditions.blank? || jids.include?(job.jid)
        end
        jobs
      end
    end
  end
end
