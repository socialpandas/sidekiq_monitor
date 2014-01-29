module Sidekiq
  module Monitor
    class Job < ActiveRecord::Base
      require 'rubygems'
      
      attr_accessible :args, :class_name, :enqueued_at, :finished_at, :jid, :name, :queue, :result, :retry, :started_at, :status if ActiveRecord::VERSION::MAJOR < 4 || Gem::Specification.all().map{|g| g.name}.include?("protected_attributes")

      serialize :args
      serialize :result

      after_destroy :delete_sidekiq_job

      @statuses = [
        'queued',
        'running',
        'complete',
        'failed'
      ]

      class << self
        attr_reader :statuses

        def add_status(status)
          @statuses << status
          @statuses.uniq!
        end

        def destroy_by_queue(queue, conditions={})
          jobs = where(conditions).where(status: 'queued', queue: queue).destroy_all
          jids = jobs.map(&:jid)
          sidekiq_queue = Sidekiq::Queue.new(queue)
          sidekiq_queue.each do |job|
            job.delete if conditions.blank? || jids.include?(job.jid)
          end
          jobs
        end
      end

      def sidekiq_item
        job = sidekiq_job
        job ? job.item : nil
      end

      def sidekiq_job
        sidekiq_queue = Sidekiq::Queue.new(queue)
        sidekiq_queue.each do |job|
          return job if job.jid == jid
        end
        nil
      end

      def delete_sidekiq_job
        return true unless status == 'queued'
        job = sidekiq_job
        job.delete if job
      end
    end
  end
end
