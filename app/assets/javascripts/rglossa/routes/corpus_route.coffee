App.CorpusRoute = Em.Route.extend

  model: (params) ->
    App.Corpus.find(params['corpus_short_name'])

  serialize: (params) ->
    {corpus_short_name: params.get('id')}


  events:
    showResult: (params) ->
      {corpus, search, pageNo} = params
      @transitionTo('corpus.result', corpus, [search, pageNo])

    showCorpusHome: ->
      # FIXME: Should we just do this for all input controllers or find another solution?
      @controllerFor('cwbSearchInputs').set('query', '')

      @transitionTo("corpus.home")
