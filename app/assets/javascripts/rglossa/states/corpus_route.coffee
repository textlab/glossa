App.CorpusRoute = Em.Route.extend

  model: (params) ->
    App.Corpus.find(params['corpus_short_name'])

  serialize: (params) ->
    {corpus_short_name: params.get('id')}


  events:
    showResults: (params) ->
      {corpus, search, pageNo} = params
      @transitionTo('corpus.results', corpus, [search, pageNo])
