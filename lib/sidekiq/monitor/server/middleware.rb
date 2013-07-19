module Sidekiq
  module Monitor
    module Server
      class Middleware
        def initialize(options=nil)
          @processor = Monitor::Processor.new
        end

        def call(worker, msg, queue)
          @processor.start(worker, msg, queue)
          begin
            return_value = yield
          rescue Exception => exception
            @processor.error(worker, msg, queue, exception)
            raise exception
          end
          @processor.complete(worker, msg, queue, return_value)
          return_value
        end
      end
    end
  end
end
