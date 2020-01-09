# frozen_string_literal: true

module JqueryTablesorter
  module RailsUtils
    module Ajax
      # Class used by ActionController concern. Encapsulates query logic.
      # For further documentation see ajax-module.
      class Handler
        def initialize(tablesorter_params)
          @ts_params = tablesorter_params
        end

        # Define the table structure
        def create_filter_info(position, options = {})
          filter = Filter.new(position, options)

          ajax_filters << filter

          filter
        end

        # Load data for the given tablesorter params in a controller action
        # Params:
        # base_query:         If there are any relevant joins or so -> pass the AR relation here
        # Returns a hash with:
        # total_rows:    How many records are there available
        # filtered_rows: How many records are left after filtering
        # records:       An collection with the resulting records
        def query_data(base_query)
          query  = base_query
          result = Hash.new

          # Filters
          query = apply_filters(query, tablesorter_params)

          # Calculate row counts
          rec_counts             = record_counts(base_query, query)
          result[:filtered_rows] = rec_counts[:filtered_rows]
          result[:total_rows]    = rec_counts[:total_rows]

          # Handle paging afterwards
          query = handle_pagination(query, tablesorter_params, result)

          # Sorting
          query = apply_sorting(query, tablesorter_params)

          result[:records] = query

          result
        end

        private

        # Calulate count of all and filtered records
        # Params:
        # model_query:    The base query of the current selection
        # filtered_query: The filtered query (relation with applied tablesorter filters)
        def record_counts(model_query, filtered_query)
          counts = Hash.new
          total  = model_query.distinct.count(:id)

          # Handle results of joined queries. This feels a little bit hacky.
          total = total.keys.length if total.is_a?(Hash)

          counts[:total_rows] = total

          if tablesorter_params[:filter]
            # Count again if additional filters were applied (fires a query)
            cnt = filtered_query.count("#{model_query.table_name}.id")

            # Handle results of having-queries. This feels a little bit hacky.
            cnt = cnt.keys.length if cnt.is_a?(Hash)

            counts[:filtered_rows] = cnt
          else
            counts[:filtered_rows] = total # There wasn't any reduction.
          end

          counts
        end

        # add filter query to sql
        def apply_filter(query, filter, value)
          return [query] if query.blank? || filter.blank? || value.blank?
          return [query] if filter.noop?

          klass  = filter.klass || query.klass
          column = filter.column
          value  = filter.values.call(value) if filter.values.present?

          queries = []

          if column.present?
            target_column = "#{klass.table_name}.#{column}"

            if filter.data_type == DateTime
              target_column = "date_trunc('second', #{target_column})"
            end

            vals  = Array(value)
            value = []
            q     = []

            vals.each do |val|
              if klass.columns_hash[column.to_s] && klass.columns_hash[column.to_s].type == :integer && !(val.to_s.strip =~ /\A\d+\Z/)
                q << '0 = 1'
              else
                q     << "LOWER(#{target_column}::varchar) LIKE LOWER(?)"
                value << "%#{val}%"
              end
            end

            queries << "(#{q.join(' OR ')})" if q.any?
          elsif filter.query.present?
            query, query_list, value_list = filter.query.call(query, value)
            queries = Array(query_list)
            value   = Array(value_list)
          elsif filter.having.present?
            query = query.having("LOWER((#{filter.having})::varchar) LIKE ?", "%#{Array(value).first}%")
          end

          [query, queries, value]
        end

        # apply global filter value for all column filters
        def apply_global_filters(query, filter_params)
          value = filter_params[:filter][999.to_s] rescue nil

          return query if value.blank?

          queries = []
          values  = []

          # iterate over all filter inputs
          ajax_filters.each do |filter|
            next if filter.blank?
            next if filter.having.present?

            query, q, v = apply_filter(query, filter, value)

            next if q.blank?

            queries += Array(q)
            values  += Array(v) unless v.nil?
          end

          query.where(queries.join(' OR '), *values)
        end

        # apply individual column filters
        def apply_filters(query, filter_params)
          query = apply_global_filters(query, filter_params)

          queries = []
          values  = []

          # iterate over all filter inputs
          (filter_params[:filter] || {}).each do |idx, value|
            ajax_filters.select { |f| f.position == idx.to_i }.each do |filter|
              next if filter.blank?
              next if filter.global?

              query, q, v = apply_filter(query, filter, value)

              next if q.blank?

              queries += Array(q)
              values  += Array(v) unless v.nil?
            end
          end

          query.where(queries.join(' AND '), *values)
        end

        # Sort the passed relation by the tablesorter-sorting.
        def apply_sorting(query, sort_params)
          (sort_params[:sort] || {}).each do |idx, order|
            order  = (order.to_i % 2 == 0) ? :asc : :desc
            filter = ajax_filters.find { |f| f.position == idx.to_i }

            next if filter.blank?

            klass  = filter.klass || query.klass
            column = filter.column

            if filter.sorter_query.present?
              query = filter.sorter_query.call(query, order)
            else
              query  = query.reorder("#{klass.table_name}.#{column} #{order} NULLS LAST")
            end
          end

          query
        end

        # Paginiation/the amount of visible rows in the table (per page)
        def handle_pagination(query, ts_params, result)
          # Tablesorter submits row count or simply 'all'. If user requests more rows
          # than available do nothing.
          return query if (ts_params[:size] == 'all') || (ts_params[:size].to_i >= result[:total_rows])

          query.limit(ts_params[:size].to_i).offset(ts_params[:size].to_i * ts_params[:page].to_i)
        end

        # Array with all currently configured Filter-Objects
        def ajax_filters
          @_ajax_table_filters ||= []
        end

        def tablesorter_params
          @ts_params
        end
      end
    end
  end
end
