module JqueryTablesorter
  module RailsUtils
    module Ajax
      # Represents a table sorting Filter. In most cases this is also a column
      # in your table, but might als be a global/external filter.
      class Filter
        # Name of the column in the DB. Used for queries, but may also be :all for glob. filters.
        attr_accessor :column_name
        # Class of the base model.
        attr_accessor :model
        # If you need to join, this is your relation table
        attr_accessor :join_rel
        # An external table column to be used with join.
        attr_accessor :external_column
        # If a having clase is required, pass it here. This will change the controll flow on
        # filter-/sorting.
        attr_accessor :having_clause
        # Optional data type of the column. This might be used to make queries more flexible.
        # For examaple, if DateTime is passed, it will strip away milliseconds from query.
        attr_accessor :data_type
        # Optional boolean filter if the given filter is a global filter or not.
        attr_accessor :global_filter
        # Optional index requested by tablesorter, needed for glob. filters.
        attr_accessor :position
        # Optional block to modify the real input of filters to match UI (e.g. Input: 'Iceland' =>  DB: 'is')
        # This block has to return an array which will be used for an IN-Query. Thus, the current implementation
        # depends on an 1:1 match.
        attr_accessor :filter_mapping

        def initialize(column_name, model_clazz, opts = {})
          @column_name     = column_name
          @model           = model_clazz
          @position        = opts[:position]
          @join_rel        = opts[:join_rel]
          @external_column = opts[:external_column]
          @having_clause   = opts[:having_clause]
          @data_type       = opts[:data_type]
          @global_filter   = opts[:global_filter]
          @filter_mapping  = opts[:filter_mapping]
        end

        def global_filter?
          @global_filter || false
        end

        def name
          self.column_name
        end

        def model_class
          self.model
        end

        def external?
          external_column.present?
        end

      end
    end
  end
end
