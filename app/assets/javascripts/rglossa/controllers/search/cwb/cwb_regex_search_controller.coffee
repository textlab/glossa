#= require rglossa/controllers/search/search_controller

App.CwbRegexSearchController = App.SearchController.extend

  # This will be bound to the search field by the template
  queryInputValue: ''

  queries: (->
    # For regex queries, the query is simply the contents of the search field.
    # TODO: support multiple search fields
    @get('queryInputValue')
  ).property('queryInputValue')