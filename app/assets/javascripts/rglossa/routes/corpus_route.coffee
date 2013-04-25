App.CorpusRoute = Em.Route.extend

  model: (params) ->
    App.Corpus.find(params['corpus_short_name'])

  serialize: (params) ->
    {corpus_short_name: params.get('id')}


  events:
    showResult: (params) ->
      {corpus, search, pageNo} = params
      @transitionTo('corpus.result', corpus, [search, pageNo])

    showCorpusHome: -> @transitionTo("corpus.home")
