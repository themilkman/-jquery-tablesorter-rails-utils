# Jquery::Tablesorter::Rails::Utils

Helpful (hopefully! ;-) ) additions for jQuery tablesorter (only support for [Mottie's fork] targeted) when working with rails.

While still in early development - which might bring breaking changes with new releases - it is meant to provide helpful utilities for jquery-tablesorter in rails. At the current state of development it only supports a mechanism to help to work with Ajax based tables.
You have a helpful idea/code snippet for something which makes it easier to work with tablesorter and rails? Cool, feel free to create a pull request!

For further information how to work with jQuery tablesorter I recommend the excellent [documentation] in [Mottie's fork].


## Installation

Please note: Tablesorter has to be installed separately from this gem. You may use my packaged version ([jquery-tablesorter-gem]) or any other way to add it to your project.

Add this line to your application's Gemfile:

~~~ruby
gem 'jquery-tablesorter-rails-utils'
~~~

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install jquery-tablesorter-rails-utils

## Usage

### Module: Ajax

The following sections shows an example how to use the Ajax module. It currently only supports PostgreSQL.

So, to query rendered HTML rows of your Foo model you may do:

In your controller (don't forget to add your routes!):

~~~ruby

class FooController < ApplicationController
  include JqueryTablesorter::RailsUtils::Ajax::ActionController

  # Ajax query for the foo list rows
  def query_list
    base_query = Foo.my_scope

    foo_columns()
    resp = create_query_response(base_query, partial: 'my_partial_foo_row')

    render json: resp
  end

  private

  def foo_columns
    ts_ajax_handler.create_filter_info(:name, Foo)
    ts_ajax_handler.create_filter_info(:other_attribute_name_of_foo, Foo)
    # Let's say, there is a global filter, too. The position is the param
    # tablesorter submits on an request.
    ts_ajax_handler.create_filter_info(:all, Foo, { global_filter: true, position: 5 })
  end

end
~~~

In the .coffee file you prepare your tablesorter instance and may add code like this:

~~~coffee

$('#my_ajax_table').tablesorter(
     # ...
    ).tablesorterPager(
      # your pager settings..
      # if data tag is given, handle this table as ajax table
      if query_url = current_table.data('query-url')
        ajax_pager =
          processAjaxOnInit: true
          ajaxUrl:           query_url
          ajaxError:         null
          ajaxObject:
            dataType: 'json'
          ajaxProcessing: (result, table, xhr) ->
            if result
              result.total        = result['total_rows']
              result.filteredRows = result['filtered_rows']
              if result.hasOwnProperty('data')
                result.rows         = $(result.data) # rendered <tr>s
              return result
    )
~~~

In your view, the table partials could look like:

~~~haml

%table#my_ajax_table{ 'data-query-url': 'foo/query?&page={page}&size={size}&{sortList:sort}&{filterList:filter}' }
  %thead
    %tr
      %th= name
      %th= other_attribute_name_of_foo
  %tfoot
    = render partial: 'your_footer_partial'
  %tbody
~~~

And the partial for the table rows:

~~~haml

= records.each do |foo|
  %tr
    %td= foo.name
    %td= foo.other_attribute_name_of_foo
~~~


## Licensing

* Licensed under the [MIT](http://www.opensource.org/licenses/mit-license.php) license.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request


[Mottie's fork]: https://github.com/Mottie/tablesorter
[documentation]: http://mottie.github.com/tablesorter/docs/index.html
[jquery-tablesorter-gem]: https://github.com/themilkman/jquery-tablesorter-rails
