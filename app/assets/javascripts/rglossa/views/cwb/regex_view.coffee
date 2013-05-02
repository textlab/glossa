App.CwbRegexView = Em.View.extend
  templateName: 'cwb/regex'

  # "query" is defined on each of the different view classes for the simple,
  # multiword and regex CWB search and bound to the CwbSearchInputsController, which
  # will create the search records.
  queryBinding: 'controller.query'

  _query: ''
  query: ((key, value) ->
    if arguments.length == 2
      # The regex view just passes along the search string to the controller.
      # Other views will process the value first.
      @_query = value
    @_query
  ).property()


  didInsertElement: ->
    @$('.searchfield').focus()
