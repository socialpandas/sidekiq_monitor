module Sidekiq
  module Monitor
    class CustomViews
      @views = []

      class << self
        def add(name, path, &block)
          @views << {
            name: name,
            path: path,
            filter: block
          }
        end

        def for_job(job)
          views = []
          @views.each do |view|
            is_valid = view[:filter].call(job)
            views << view.dup if is_valid
          end
          views
        end
      end
    end
  end
end
