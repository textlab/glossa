App.CorpusController = Em.ObjectController.extend

  # Search type, depending on chosen corpus. Defaults to the Corpus Workbench.
  searchType: (->
    @get('model.searchType') or 'cwb'
  ).property('model.searchType')
