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
    end
  end
end
