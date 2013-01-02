App.CwbSearchesController = Em.ArrayController.extend
  content: []

  # This will be set to the controller for the currently active search
  # type (regex, multiword, simple etc.)
  searchTypeController: null
  queryBinding: 'searchTypeController.queries'

  corpusBinding: 'corpusController.content'

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