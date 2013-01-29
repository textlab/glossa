App.SearchesController = Em.ArrayController.extend
  content: []

  needs: 'corpus'

  # This will be bound to properties on views for for simple search, multiword
  # search and regex search.
  query: ''

  corpus: null
  corpusBinding: 'controllers.corpus.content'

  searchModelClassBinding: 'controllers.corpus.searchModelClass'

  # Action handler
  search: -> @createSearch()

  createSearch: ->
    metadataValueIds = {}
    metadataValueIds[@get('corpus.id')] = [1,2,3]

    # TODO: Add support for simultaneous search in different "editions" within
    # the same corpus (e.g. different languages in a parallel corpus). Each
    # edition will have a distinct shortName.
    queries = [
      corpusEdition: @get('corpus.shortName')
      query:         @get('query')
    ]

    search = @get('searchModelClass').createRecord(
      metadataValueIds: metadataValueIds
      queries: queries)

    @get('store').commit()

    @pushObject(search)