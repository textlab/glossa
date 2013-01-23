App.CwbRegexView = Em.View.extend
  templateName: 'search/cwb_regex'

  # This is defined on each of the different view classes for the simple,
  # multiword and regex CWB search and bound to the CwbSearchesController,
  # which will create the search records.
  queryBinding: 'controller.query'

  # This will be bound to the search field by the template
  queryInputValue: ''

  queryInputValueDidChange: (->
    # For regex queries, the query is simply the contents of the search field.
    # TODO: support multiple search fields for different corpus editions (e.g.
    # languages in a parallel corpus)
    @set('query', @get('queryInputValue'))
  ).observes('queryInputValue')


  didInsertElement: ->
    @$('.searchfield').focus()
