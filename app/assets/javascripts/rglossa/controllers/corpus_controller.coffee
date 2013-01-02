App.CorpusController = Em.ObjectController.extend

  # Search type, depending on chosen corpus. Defaults to the Corpus Workbench.
  searchType: (->
    @get('content.searchType') or 'cwb'
  ).property('content.searchType')


  setCorpus: (shortName) ->
    corpus = App.Corpus.find({ shortName: shortName })
    @set('content', corpus)
    corpus
