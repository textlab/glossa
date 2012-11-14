App.SelectedCorpusController = Em.ObjectController.extend

  # Search type, depending on chosen corpus. Defaults to the Corpus Workbench.
  searchType: 'cwb'

  initCorpus: (corpus) ->
    @set('content', corpus)

    searchType = corpus.get('searchType')
    @set('searchType', searchType) if searchType