# frozen_string_literal: true

# Adds mechanisms to work with Ajax based tables and tablesorter.
module JqueryTablesorter
  module RailsUtils
    module Ajax
      require 'jquery-tablesorter/rails-utils/ajax/filter'
      require 'jquery-tablesorter/rails-utils/ajax/handler'
      require 'jquery-tablesorter/rails-utils/ajax/action_controller'
    end
  end
end
