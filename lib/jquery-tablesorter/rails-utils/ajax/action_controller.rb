# frozen_string_literal: true

# Controller concern to help with ajax jquery tablesorter requests.
# It handles sorting and filtering.
# Current limitions (extract ;-P):
# * It does not support sorting by multiple columns.
#
# Usage:
# Include module in controller and call methods in query-action,
# where the results can be used to build the response.
#
# Further ToDos/plans/ideas/dreams:
# * Also, there might be a possibility to pass a block for each column-operation such
#   as filtering or sorting and allow more dynamic work. This might happen before or better
#   instead the standard processing.
# * Maybe it'd be possible to allow multi-column sorting somehow.
# * In some cases it could make sense not to cast all columns to strings/varchars. So, an optionally passed
#   type for a column might get evaluated/used in a different manner.
# * Evaluate if the position of a column should be passed to the columns (in other words:  useful?!)
module JqueryTablesorter
  module RailsUtils
    module Ajax
      module ActionController
        extend ActiveSupport::Concern

        # A generalized method to handle tablesorter queries. It's meant to be used in the corresponding
        # Controller action. Params:
        # clazz:              The model's primary class
        # base_query:         If there are any relevant joins or so -> pass the AR relation here
        # partial (optional): path to the partial to be rendered
        def create_query_html_response(base_query, partial: 'row', locals: {})
          resp_data        = ts_ajax_handler.query_data(base_query)
          records          = resp_data.delete(:records)
          resp_data[:data] = render_response_html(records, partial: partial, locals: locals)

          resp_data
        end

        private

        # Render the html rows for the given records and an optional named partial.
        # Returns HTML string or nil
        def render_response_html(records, partial: 'row', locals: {} )
          output = render_to_string(partial: partial, locals: { records: records }.merge(locals))

          # if the query has no results, it will return a string which causes jquery to crash
          output = nil unless records.any?

          output
        end

        def ts_ajax_handler
          @_ts_ajax_handler ||= Handler.new(tablesorter_params)
        end

        def tablesorter_params
          params.permit(
            :page, :size, :controller, :action, :query, :sort, :filter,
            { sort:   params[:sort].try(:keys) },
            { filter: params[:filter].try(:keys) }
          )
        end
      end
    end
  end
end
