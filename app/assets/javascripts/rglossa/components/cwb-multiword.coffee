# Helper object
App.CwbMultiwordTerm = Em.Object.extend
  word:     ''
  pos:      null
  features: null
  min:      null
  max:      null

  isLemma: false
  isStart: false
  isEnd:   false

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
    @$().on 'focusout', '.ember-text-field', $.proxy(@updateQuery, @)

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
        word    = item.substring(1, item.length-1)
        isStart = /\.\+$/.test(word)
        isEnd   = /^\.\+/.test(word)
        word = word.replace(/^(?:\.\+)?(.+?)/, "$1").replace(/(.+?)(?:\.\+)?$/, "$1")

        dq.push App.CwbMultiwordTerm.create
          word:     word
          features: []
          min:      min
          max:      max
          isStart:  isStart
          isEnd:    isEnd

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
      isLemma  = term.get('isLemma')
      isStart  = term.get('isStart')
      isEnd    = term.get('isEnd')
      pos      = term.get('pos')
      features = term.get('features')
      attrs    = []

      if isLemma or pos or features.length
        if word
          attr = if isLemma then 'lemma' else 'word'
          word = "#{word}.+" if isStart
          word = ".+#{word}" if isEnd
          word = "(#{attr}=\"#{word}\" %c)"
          attrs.push(word)

        if pos
          pos = "ordkl=\"#{pos.value}\""
          attrs.push(pos)

        for feature in features
          f = "#{feature.attr}=\"#{feature.value}\""
          attrs.push(f)

        str = '[' + attrs.join(' & ') + ']'
      else
        # Only the word attribute is specified, so use a simple string
        str = if word
          word = "#{word}.+" if isStart
          word = ".+#{word}" if isEnd
          "\"#{word}\""
        else ''
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
      'displayedQuery.@each.max',
      'displayedQuery.@each.isLemma')


  _splitQueryTerms: ->
    query = @get('query')
    query.match(/\[\]\{(.+)\}|"[^"\s]+"|\[[^\]]+\]/g) or ['']


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
      features: []

    for attr in attributes
      m2 = attr.match(/\(?(\S+)\s*=\s*"(\S+)"/)
      switch m2[1]
        when 'word', 'lemma'
          term.set('word',    m2[2])
          term.set('isLemma', m2[1] is 'lemma')
          term.set('isStart', /\.\+$/.test(m2[2]))
          term.set('isEnd',   /^\.\+/.test(m2[2]))
        when 'pos' then term.set('ordkl', m2[2])
        else term.get('features').pushObject(attr: m2[1], value: m2[2])

      # Remove any .+ at the beginning and/or end of the displayed form
      term.set('word', term.get('word').replace(/^(?:\.\+)?(.+?)/, "$1").replace(/(.+?)(?:\.\+)?$/, "$1"))
    term

  updateQuery: -> @set('query', @_query)

  addTerm: ->
    newTerm = App.CwbMultiwordTerm.create
      features: []
      isLast: true

    dq = @get('displayedQuery')
    dq[dq.length-1].set('isLast', false)
    dq.pushObject(newTerm)
    @updateQuery()


  removeTerm: (term) ->
    dq = @get('displayedQuery')
    return unless dq.get('length') > 1 # must contain at least one term

    dq.removeObject(term)

    # If we removed the first term, we need to mark the new first term as being
    # first.
    dq.objectAt(0).set('isFirst', true) if term.isFirst
    dq.get('lastObject').set('isLast', true) if term.isLast
    @updateQuery()


  action: 'search'
  search: ->
    @updateQuery()
    # Run on the next runloop to enable the change to propagate to the
    # CwbSearchInputsController
    Em.run.next => @sendAction()
