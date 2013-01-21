App.CorpusController = Em.ObjectController.extend

  # Search engine, depending on chosen corpus. Defaults to the Corpus Workbench.
  searchEngine: (->
    @get('model.searchEngine') or 'cwb'
  ).property('model.searchEngine')
