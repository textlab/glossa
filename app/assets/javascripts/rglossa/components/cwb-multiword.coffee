# Helper object
App.CwbMultiwordTerm = Em.Object.extend
  word:     ''
  pos:      null
  features: null
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
      if m = item.match(/\[\]\{(.+)\}/)
        [min, max] = @_handleIntervalSpecification(m)
      else if m = item.match(/\[(.+)\]/) 
        dq.push @_handleAttributes(m, min, max)
        min = null
        max = null
      else
        dq.push App.CwbMultiwordTerm.create
          word: item.substring(1, item.length-1)
          features: []

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
      min      = term.get('min')
      max      = term.get('max')
      word     = term.get('word')
      pos      = term.get('pos')
      features = term.get('features')
      attrs    = []

      if pos or features.length
        if word
          word = "(word=\"#{word}\" %c)"
          attrs.push(word)

        if pos
          pos = "ordkl=\"#{pos.value}\""
          attrs.push(pos)

        for feature in features
          f = "#{feature.attr}=\"#{feature.value}\""
          attrs.push(f)

        str = '[' + attrs.join(' & ') + ']'
      else
        str = if word then "\"#{word}\"" else ''

      if min or max
        str = "[]{#{min ? ''},#{max ? ''}} " + str

      str

    # Assign the query value to a private variable, which will not be
    # transferred to the query property until we recieve a focusOut event.
    # Otherwise, displayedQuery will be updated in turn when query is set,
    # which leads to the input field that we are editing losing focus.
    @_query = terms.join(' ')
  ).observes('displayedQuery.@each.word',
      'displayedQuery.@each.pos',
      'displayedQuery.@each.min',
      'displayedQuery.@each.max')


  _splitQueryTerms: ->
    query = @get('query')
    query.match(/"[^"\s]+"|\[[^\]]+\]/g) or ['']


  _handleIntervalSpecification: (m) ->
    intervalText = m[1]
    min = max = null

    m2 = intervalText.match(/(\d+),/)
    min = m2[1] if m2

    m2 = intervalText.match(/,(\d+)/)
    max = m2[1] if m2

    [min, max]


  _handleAttributes: (m, min, max) ->
    attributes = m[1].split(/\s*&\s*/)
    term = App.CwbMultiwordTerm.create
      min: min
      max: max

    for attr in attributes
      m2 = attr.match(/(\S+)\s*=\s*"(\S+)"/) 
      switch m2[1]
        when 'word' then term.set('word',  m2[2])
        when 'pos'  then term.set('ordkl', m2[2])
        else term.set(m2[1], m2[2])
    term

  addTerm: ->
    newTerm = App.CwbMultiwordTerm.create
      features: []
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
