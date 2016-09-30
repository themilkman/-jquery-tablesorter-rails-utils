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
        def create_filter_info(column_name, model_clazz, filter_opts = {})
          filter = Filter.new(column_name, model_clazz, filter_opts)
          ajax_filters << filter
          return filter
        end

        # Load data for the given tablesorter params in a controller action
        # Params:
        # base_query:         If there are any relevant joins or so -> pass the AR relation here
        # Returns a hash with:
        # total_rows:    How many records are there available
        # filtered_rows: How many records are left after filtering
        # records:       An collection with the resulting records
        def query_data(base_query)
          @query      = base_query

          result      = Hash.new

          # Filters
          @query = apply_filters(@query, tablesorter_params)

          # Calculate row counts
          rec_counts             = record_counts(base_query, @query)
          result[:filtered_rows] = rec_counts[:filtered_rows]
          result[:total_rows]    = rec_counts[:total_rows]

          # Handle paging afterwards
          @query = handle_pagination(@query, tablesorter_params, result)

          # Sorting
          @query = apply_sorting(@query, tablesorter_params)

          result[:records] = @query

          return result
        end

        # Calulate count of all and filtered records
        # Params:
        # model_query:    The base query of the current selection
        # filtered_query: The filtered query (relation with applied tablesorter filters)
        def record_counts(model_query, filtered_query)
          counts              = Hash.new
          total               = model_query.distinct.count(:id)

          if total.is_a?(Hash) # Handle results of joined queries. This feels a little bit hacky.
            total = total.keys.length
          end

          counts[:total_rows] = total

          if tablesorter_params[:filter]
            # Count again if additional filters were applied (fires a query)
            cnt = filtered_query.count("#{model_query.table_name}.id")

            if cnt.is_a?(Hash) # Handle results of having-queries. This feels a little bit hacky.
              cnt = cnt.keys.length
            end
            counts[:filtered_rows] = cnt
          else
            counts[:filtered_rows] = total # There wasn't any reduction.
          end

          return counts
        end


        # let every special case be handled within that block.
        # block should remove the values from the params parameter to allow regular processing.
        def apply_filters(record_relation, filter_params)
          splat_global_filter(filter_params)
          record_relation = apply_global_filters(record_relation, filter_params)

          # iterate over all filter inputs
          (filter_params[:filter] || {}).each do |filter_index, filter_value|
            sel_col = ajax_filters[filter_index.to_i]
            next if sel_col.blank?

            clazz           = sel_col.model
            selected_column = sel_col.name

            if sel_col.external? # query an external model
              ext_query       = "LOWER(#{sel_col.join_rel}.#{sel_col.external_column}::varchar) LIKE LOWER(?)"
              record_relation = record_relation.where(ext_query, "%#{filter_value}%")

            elsif sel_col.having_clause
              clause          = sel_col.having_clause
              record_relation = record_relation.having("LOWER((#{clause})::varchar) LIKE ?", "%#{filter_value}%")

            elsif sel_col.filter_mapping # there were modifications on the query
              target_col      = "#{clazz.table_name}.#{selected_column}"
              values          = sel_col.filter_mapping.call(filter_value)
              # Maybe we could use an SIMILAR TO query for this.
              record_relation = record_relation.where("LOWER(#{target_col}::varchar) IN (?)", values )

            else # directly on current model
              target_col = "#{clazz.table_name}.#{selected_column}"
              if sel_col.data_type == DateTime
                target_col = "date_trunc('minute', #{target_col})"
              end
              record_relation = record_relation.where("LOWER(#{target_col}::varchar) LIKE LOWER(?)", "%#{filter_value}%" )
            end

          end

          return record_relation
        end

        # Sort the passed relation by the tablesorter-sorting.
        def apply_sorting(record_relation, sort_params)
          (sort_params[:sort] || {}).each do |sort_index, order|
            order   = (order.to_i % 2 == 0) ? :asc : :desc
            sel_col = ajax_filters[sort_index.to_i]

            if sel_col.external?
              order_query     = [sel_col.join_rel, sel_col.external_column].compact.join('.')
              record_relation = record_relation.order("#{order_query} #{order}")

            elsif sel_col.having_clause
              # If there is a having_clause, use the column name w/o tablename
              record_relation = record_relation.order("#{sel_col.name} #{order} NULLS LAST")

            else
              order_query     = [sel_col.model.table_name, sel_col.name].compact.join('.')
              record_relation = record_relation.order("#{order_query} #{order} NULLS LAST")
            end

          end

          return record_relation
        end

        # Paginiation/the amount of visible rows in the table (per page)
        def handle_pagination(query, ts_params, result)
          # Tablesorter submits row count or simply 'all'. If user requests more rows
          # than available do nothing.
          return query if ( (ts_params[:size] == 'all') || (ts_params[:size].to_i >= result[:total_rows]) )

          query = query
                      .limit(ts_params[:size].to_i)
                      .offset(ts_params[:size].to_i * ts_params[:page].to_i)

          return query
        end

        # Array with all currently configured Filter-Objects
        def ajax_filters
          @_ajax_table_filters ||= []
        end

        private

        def tablesorter_params
          @ts_params
        end

        # Iterate over all columns with the (previous in *splat_global_filter* initialized)
        # global filter value
        def apply_global_filters(record_relation, filter_params)
          # TODO Wouldn't it be smarter to make query an array and join it by ' OR '?
          query         = ''
          filter_values = []

          (filter_params[:global_filter] || {}).each do |filter_index, filter_value|
            sel_col = ajax_filters[filter_index.to_i]
            next if sel_col.blank?

            clazz           = sel_col.model
            selected_column = sel_col.name
            table_name      = clazz.table_name

            if sel_col.external? # Query an external model
              query         << "LOWER(#{sel_col.join_rel}.#{sel_col.external_column}::varchar) LIKE LOWER(?) OR "
              filter_values << "%#{filter_value}%"

            elsif sel_col.filter_mapping # there were modifications on the query
              target_col     = "#{clazz.table_name}.#{selected_column}"
              values         = sel_col.filter_mapping.call(filter_value)
              # Maybe we could use an SIMILAR TO query for this.
              query         << "LOWER(#{target_col}::varchar) IN (?) OR "
              filter_values << values

            elsif sel_col.having_clause
              # Having clauses will create an extra query to select IDs of base-table records
              # an add them into the main query as IN <ids>.
              # If there is a having_clause, use the column name only w/o tablename.
              clause        = "LOWER(#{sel_col.having_clause}::varchar) LIKE LOWER(?)"
              filter_values << record_relation.having(clause, "%#{filter_value}%")
                                              .pluck(:id)
              query         << "#{table_name}.id IN (?) OR "

            else
              target_col = "#{table_name}.#{selected_column}"

              if sel_col.data_type == DateTime # Special handling for Dates -> strip away millisecs
                target_col = "date_trunc('second', #{target_col})"
              end

              query         << "LOWER(#{target_col}::varchar) LIKE LOWER(?) OR "
              filter_values << "%#{filter_value}%"
            end
          end

          query = query.chomp(' OR ') # remove the last OR

          return record_relation.where(query, *filter_values)

        end

        # If any global filter value (the user input) is found (which currently is asumed to the last),
        # take this input and add it to a global_filter subkey with the corresponding index of each
        # not global-filter column. Thus, later the may be used to check all coulmns for the given
        # input.
        def splat_global_filter(filter_params)
          # Global filter params is assumed to be at the last index
          global_filter = ajax_filters.find { |c| c.global_filter? }
          return unless global_filter

          global_filter_value = filter_params.dig(:filter, global_filter.position.to_s)
          return if global_filter_value.nil?

          filter_params[:global_filter] ||= {}
          ajax_filters.each_with_index do |col, idx|
            next if (col.nil? || col.global_filter?)
            # Add search query for each (non-global) value
            filter_params[:global_filter][idx.to_s] = global_filter_value
          end

          # Remove the global filter from the params
          filter_params[:filter].delete(global_filter.position.to_s)
        end

      end
    end
  end
end
