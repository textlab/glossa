App.CwbSimpleComponent = Em.Component.extend

  # Private variable that holds the currently displayed query, which is
  # transferred to the public query property on reception of a focusOut event
  # or a search action
  _query: null

  displayedQuery: (->
    # Take the CQP expression and just remove quotes
    @_query = @get('query')
    @_query.replace(/"/g, '')
  ).property('query')

  displayedQueryDidChange: (->
    # Assign the query value to a private variable, which will not be
    # transferred to the query property until we recieve a focusOut event.
    # Otherwise, displayedQuery will be updated in turn when query is set,
    # which leads to the input field that we are editing losing focus.
    @_query = ("\"#{term}\"" for term in @get('displayedQuery').split(/\s+/)).join(' ')
  ).observes('displayedQuery')

  focusOut: -> @set('query', @_query)

  action: 'search'
  search: -> 
    @set('query', @_query)
    @sendAction()
