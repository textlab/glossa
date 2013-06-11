App.CwbMultiwordView = Em.View.extend
  templateName: 'cwb/multiword'

  # "query" is defined on each of the different view classes for the simple,
  # multiword and regex CWB search and bound to the CwbSearchInputsController, which
  # will create the search records.
  queryBinding: 'controller.query'

  displayedQuery: ((key, value) ->
    if value
      query = value.replace(/\S+/g, '"$&"')
      @set 'query', query

    query = @_splitQueryTerms()

    dq = []
    @interval = {}

    query.forEach (term) =>
      m = term.match(/\[\]\{(.+)\}/)
      if m
        @_handleIntervalSpecification(m)
      else
        dq.push
          word: term
          interval: @interval

        @interval = {}
    dq
  ).property('query')


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

    @interval = {min: min, max: max}

