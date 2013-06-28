App.CwbMultiwordView = Em.View.extend
  templateName: 'cwb/multiword'

  # "query" is defined on each of the different view classes for the simple,
  # multiword and regex CWB search and bound to the CwbSearchInputsController, which
  # will create the search records.
  queryBinding: 'controller.query'

  displayedQuery: (->
    query = @_splitQueryTerms()

    dq = []
    min = null
    max = null

    query.forEach (term) =>
      m = term.match(/\[\]\{(.+)\}/)
      if m
        [min, max] = @_handleIntervalSpecification(m)
      else
        dq.push
          word: term
          min: min
          max: max

        min = null
        max = null
    dq
  ).property()


  displayedQueryDidChange: (->
    displayedQuery = @get('displayedQuery')

    terms = for term in displayedQuery
      res = []
      if term.min or term.max
        res.push("[]{#{term.min ? ''},#{term.max ? ''}}")  # interval
      res.push term.word.replace(/\S+/g, '"$&"')           # word
      res.join(' ')

    @set 'query', terms.join(' ')

  ).observes('displayedQuery.@each.word',
      'displayedQuery.@each.min',
      'displayedQuery.@each.max')


  didInsertElement: ->
    @$('.searchfield').first().focus()
    @$('div.interval').first().hide()
    @$('div.interval-filler').first().hide()
    @$('div.add-search-word').last().show()


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

