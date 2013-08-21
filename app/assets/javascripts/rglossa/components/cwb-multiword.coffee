# Helper object
App.CwbMultiwordTerm = Em.Object.extend
  word:     null
  min:      null
  max:      null

  isFirst:  false
  isLast:   false

  isFirstDidChange: ->
    # The first term cannot be preceded by an interval
    if @get('isFirst')
      @set('min', null)
      @set('max', null)


App.CwbMultiwordComponent = Em.Component.extend

  # Private variable that holds the currently displayed query, which is
  # transferred to the public query property on reception of a focusOut event
  # or a search action
  _query: null

  didInsertElement: ->
    @$().on 'focusout', '.ember-text-field', => @set('query', @_query)

  willDestroyElement: ->
    @$().off 'focusout'

  displayedQuery: (->
    @_query = @get('query')
    query = @_splitQueryTerms()

    dq = []
    min = null
    max = null

    query.forEach (item) =>
      m = item.match(/\[\]\{(.+)\}/)
      if m
        [min, max] = @_handleIntervalSpecification(m)
      else
        dq.push App.CwbMultiwordTerm.create
          word: item
          min: min
          max: max

        min = null
        max = null

    # Ugly hack that is needed because the #each Handlebars helper
    # does not provide array indices to the templates in the loop :-/
    dq[0].isFirst = true
    dq[dq.length-1].isLast = true
    dq
  ).property()


  displayedQueryDidChange: (->
    displayedQuery = @get('displayedQuery')

    terms = for term in displayedQuery
      min  = term.get('min')
      max  = term.get('max')
      word = term.get('word')
      res  = []

      if min or max
        res.push("[]{#{min ? ''},#{max ? ''}}")  # interval
      res.push word.replace(/\S+/g, '"$&"')      # word
      res.join(' ')

    # Assign the query value to a private variable, which will not be
    # transferred to the query property until we recieve a focusOut event.
    # Otherwise, displayedQuery will be updated in turn when query is set,
    # which leads to the input field that we are editing losing focus.
    @_query = terms.join(' ')
  ).observes('displayedQuery.@each.word',
      'displayedQuery.@each.min',
      'displayedQuery.@each.max')


  _splitQueryTerms: ->
    query = @get('query')
    query = query.replace(/"(.*?)"/g, '$1')
    query.split(/\s+/)


  _handleIntervalSpecification: (m) ->
    intervalText = m[1]
    min = max = null

    m2 = intervalText.match(/(\d+),/)
    min = m2[1] if m2

    m2 = intervalText.match(/,(\d+)/)
    max = m2[1] if m2

    [min, max]


  addTerm: ->
    newTerm = App.CwbMultiwordTerm.create
      word: ''
      min: null
      max: null
      isLast: true

    dq = @get('displayedQuery')
    dq[dq.length-1].set('isLast', false)
    dq.pushObject(newTerm)


  removeTerm: (term) ->
    dq = @get('displayedQuery')
    dq.removeObject(term)

    # If we removed the first term, we need to mark the new first term as being
    # first.
    dq.objectAt(0).set('isFirst', true) if term.isFirst
    dq.get('lastObject').set('isLast', true) if term.isLast


  action: 'search'
  search: ->
    @set('query', @_query)
    # Run on the next runloop to enable the change to propagate to the
    # CwbSearchInputsController
    Em.run.next => @sendAction()
