App.CwbSimpleView = Em.View.extend
  templateName: 'cwb/simple'

  # "query" is defined on each of the different view classes for the simple,
  # multiword and regex CWB search and bound to the CwbSearchInputsController, which
  # will create the search records.
  queryBinding: 'controller.query'

  displayedQuery: ((key, value) ->
    if value
      query = value.replace(/\S+/g, '"$&"')
      @set 'query', query

    query = @get('query')
    query.replace(/"(.+?)"/g, '$1')
  ).property('query')

  didInsertElement: ->
    @$('.searchfield').focus()