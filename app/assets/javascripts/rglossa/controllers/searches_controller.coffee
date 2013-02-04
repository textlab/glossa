App.SearchesController = Em.ArrayController.extend
  content: []
  currentSearch: null

  needs: ['corpus', 'resultTable']

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

    @pushObject(search)
    @set('currentSearch', search)

    # Setup a one-time observer for the `id` property of the search object,
    # which will send an event to the router to make it transition to the
    # search results view when the search data has returned from the server.
    # (A more natural thing to observe would be the `isNew` property, but due
    # to a bug in Ember Data, the id has not yet been set when `isNew` becomes
    # false.)
    search.addObserver('id', @, @_sendShowResultEvent)
    search.get('transaction').commit()


  _sendShowResultEvent: ->
    search = @get('currentSearch')

    if search.get('id')
      @set('controllers.resultTable.content', search.getResultPage(1))

      @get('target').send 'showResult',
        corpus: @get('corpus')
        search: search
        pageNo: 1

      search.removeObserver('id', @, @_sendShowResultEvent)
