App.CorpusRoute = Em.Route.extend

  model: (params) ->
    App.Corpus.find(params['corpus_short_name'])

  events:
    showResults: (params) ->
      {corpusId, searchId, pageNo} = params
      @transitionTo('corpus.results', corpusId, [searchId, pageNo])
