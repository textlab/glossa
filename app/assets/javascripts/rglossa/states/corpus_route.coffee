App.CorpusRoute = Em.Route.extend

  model: (params) ->
    App.Corpus.find(params['corpus_short_name'])
