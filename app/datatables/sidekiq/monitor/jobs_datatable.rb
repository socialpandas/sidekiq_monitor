module Sidekiq
  module Monitor
    class JobsDatatable < RailsDatatables
      include ActionView::Helpers::DateHelper

      @search_filters = []

      class << self
        attr_reader :search_filters

        def add_search_filter(search_filter)
          @search_filters << search_filter
        end
      end

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
        if ::Rails::VERSION::MAJOR >= 4
          words = distance_of_time_in_words(from_time, to_time, include_seconds: true)
        else
          words = distance_of_time_in_words(from_time, to_time, true)
        end
        words.gsub('less than ', '').gsub('about ', '')
      end

      def search_records(records)
        if params[:sSearch].present?
          records = apply_search_value_to_records(params[:sSearch], records)
        end
        conditions = @columns.each_with_index.map do |column, index|
          value = params[:"sSearch_#{index}"]
          search_condition(column, value) if value.present?
        end
        conditions = conditions.compact.reduce(:and)
        records = records.where(conditions) if conditions.present?
        records
      end

      def apply_search_value_to_records(search_value, records)
        search_terms = []
        search_value.split.each do |search_term|
          filter_applied = false
          self.class.search_filters.each do |search_filter|
            if search_term =~ search_filter[:pattern]
              records = search_filter[:filter].call(search_term, records)
              filter_applied = true
              break
            end
          end
          search_terms << search_term unless filter_applied
        end
        value = search_terms.join(' ')
        conditions = @searchable_columns.map do |column|
          search_condition(column, value)
        end
        conditions = conditions.reduce(:or)
        records = records.where(conditions)
        records
      end

      def search_condition(column, value)
        column = column.split('.').last
        column_hash = @model_name.columns_hash[column]
        if column_hash && [:string, :text].include?(column_hash.type)
          return @model_name.arel_table[column].matches("%#{value}%")
        end
        @model_name.arel_table[column].eq(value)
      end
    end
  end
end
