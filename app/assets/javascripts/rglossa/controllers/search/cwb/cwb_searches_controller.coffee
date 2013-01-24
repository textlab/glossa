App.CwbSearchesController = Em.ArrayController.extend
  content: []

  needs: 'corpus'

  # This will be bound to properties on views for for simple search, multiword
  # search and regex search.
  query: ''

  corpus: null
  corpusBinding: 'controllers.corpus.content'

  # Action handler
  search: -> @createCwbSearch()

  createCwbSearch: ->
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

    @get('store').commit()

    @pushObject(search)