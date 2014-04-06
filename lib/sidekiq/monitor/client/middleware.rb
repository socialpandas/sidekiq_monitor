module Sidekiq
  module Monitor
    module Client
      class Middleware
        def initialize(options=nil)
          @processor = Monitor::Processor.new
        end

        def call(worker_class, item, queue)
          ActiveRecord::Base.connection_pool.with_connection do
            @processor.queue(worker_class, item, queue)
            yield
          end
        end
      end
    end
  end
end
