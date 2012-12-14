App.CwbSearchesController = Em.ArrayController.extend
  content: []

  # This will be set to the controller for the currently active search
  # interface (regex, multiword or simple)
  currentSearchController: null
  queryBinding: 'currentSearchController.queries'

  corpusBinding: 'selectedCorpusController.content'

  createCwbSearch: ->
    # TODO: Add support for searching in multiple corpora simultaneously
    metadataValueIds = {}
    metadataValueIds[@get('corpus.id')] = [1,2,3]

    # TODO: Add support for simultaneous search in different "editions" within
    # the same corpus (e.g. different languages in a parallel corpus). Each
    # edition will have a distinct shortName.
    queries = [
      corpusEdition: @get('corpus.shortName')
      query:         @get('query')
    ]

    search = App.CwbSearch.createRecord(
      metadataValueIds: metadataValueIds
      queries: queries)

    @pushObject(search)