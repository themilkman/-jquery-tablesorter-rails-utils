# Adds mechanisms to work with Ajax based tables and tablesorter.
# Current limitions (extract ;-P):
# * It does not support sorting by multiple columns.
# * Currently only PostgreSQL is supported
#
# Usage:
# Includet this module in your controller and call methods in your query-action,
# where the results can be used to build the response.
#
# Further ToDos/plans/ideas/dreams:
# * There might be a possibility to pass a block for each column-operation such
#   as filtering or sorting and allow more dynamic work. This might happen before or better
#   instead the standard processing. (partly done with the filter_mapping filter-parameter)
# * Maybe it'd be possible to allow multi-column sorting somehow.
# * In some cases it could make sense not to cast all columns to strings/varchars. So, an optionally passed
#   type for a column might get evaluated/used in a different manner. (done for DateTime)

module JqueryTablesorter
  module RailsUtils
    module Ajax
      require 'jquery-tablesorter/rails-utils/ajax/filter'
      require 'jquery-tablesorter/rails-utils/ajax/handler'
      require 'jquery-tablesorter/rails-utils/ajax/action_controller'
    end
  end
end
