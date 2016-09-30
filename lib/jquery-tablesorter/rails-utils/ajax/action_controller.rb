# Controller concern to help with ajax jquery tablesorter requests.
# It handles sorting and filtering.

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
        def create_query_html_response(base_query, partial: 'row')
          resp_data         = ts_ajax_handler.query_data(base_query)

          records           = resp_data.delete(:records)
          resp_data[:data]  = render_response_html(records, partial: partial)

          return resp_data
        end

        private

        # Render the html rows for the given records and an optional named partial.
        # Returns HTML string or nil
        def render_response_html(records, partial: 'row' )
          output = render_to_string partial: partial, locals: { records: records }

          unless records.any? # if the query had 0 results, it will return a string which has let jquery crash
            output = nil
          end

          return output
        end

        def ts_ajax_handler
          @_ts_ajax_handler ||= Handler.new(tablesorter_params)
        end

        def tablesorter_params
          params.permit(:page, :size, :controller, :action, :query, :sort, :filter,
            { sort:           params[:sort].try(:keys) },
            { filter:         params[:filter].try(:keys) })
        end

      end
    end
  end
end
