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


App.CwbMultiwordController = Em.Controller.extend

  # "query" is defined on each of the different controllers for the simple,
  # multiword and regex CWB search and bound to the CwbSearchInputsController, which
  # will create the search records.
  needs: ['cwbSearchInputs']

  queryBinding: 'controllers.cwbSearchInputs.query'

  displayedQuery: (->
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
  ).property('query')


  displayedQueryDidChange: (->
    displayedQuery = @get('displayedQuery')

    terms = for term in displayedQuery
      min  = term.get('min')
      max  = term.get('max')
      word = term.get('word')
      res  = []

      if min or max
        res.push("[]{#{min ? ''},#{max ? ''}}")  # interval
      res.push word.replace(/\S+/g, '"$&"')           # word
      res.join(' ')

    @set 'query', terms.join(' ')

  ).observes('displayedQuery.@each.word',
      'displayedQuery.@each.min',
      'displayedQuery.@each.max')


  _splitQueryTerms: ->
    query = @get('query')
    query = query.replace(/"(.+?)"/g, '$1')
    query.split(/\s+/)


  _handleIntervalSpecification: (m) ->
    intervalText = m[1]
    min = max = null

    m2 = intervalText.match(/(\d+),/)
    min = m2[1] if m2

    m2 = intervalText.match(/,(\d+)/)
    max = m2[1] if m2

    [min, max]

  removeTerm: (term) ->
    newDQ = (t for t in @get('displayedQuery') when t isnt term)

    # If we removed the first term, we need to mark the new first term as being
    # first.
    newDQ[0].set('isFirst', true) if term.isFirst

    @set('displayedQuery', newDQ)
