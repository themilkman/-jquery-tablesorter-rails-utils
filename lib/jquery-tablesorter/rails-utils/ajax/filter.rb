# frozen_string_literal: true

module JqueryTablesorter
  module RailsUtils
    module Ajax
      # Represents a table sorting Filter.
      class Filter
        attr_reader :position, :options

        def initialize(position, options = {})
          @position = position || (options[:global] ? 999 : nil)
          @options  = options
        end

        # dummy filter that will does nothing
        def noop?
          !!@options[:noop]
        end

        # filter that is only applied on global filtering
        def global?
          @options[:global] || false
        end

        # data type of column for special handling
        def data_type
          @options[:data_type].presence
        end

        # model class that has the specified column
        def klass
          @options[:class].presence
        end

        # column that should be filtered on
        def column
          @options[:column].presence
        end

        # proc for filtering/mapping values
        def values
          @options[:values].presence
        end

        # proc for custom query modifications
        def query
          @options[:query].presence
        end

        # proc for custom column sorter
        def sorter_query
          @options[:sorter_query].presence
        end

        # string with sql having condition
        def having
          @options[:having].presence
        end
      end
    end
  end
end
