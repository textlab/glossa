App.SearchesController = Em.ArrayController.extend

  currentSearch: null

  needs: ['corpus', 'corpusMetadataCategory']

  corpus: null
  corpusBinding: 'controllers.corpus.model'

  createSearch: (searchModel, queries) ->
    # Empty queries are not allowed
    return unless queries.some (query) ->
      query.query isnt ''

    metadataValueIds = @get('controllers.corpusMetadataCategory').collectMetadataValues()

    search = App.get(searchModel).createRecord(
      metadataValueIds: metadataValueIds
      queries: queries)

    @pushObject(search)
    @set('currentSearch', search)

    # Setup a one-time observer for the `id` property of the search object,
    # which will send an event to the router to make it transition to the
    # search results view when the search data has returned from the server.
    # (A more natural thing to observe would be the `isNew` property, but due
    # to a bug in Ember Data, the id has not yet been set when `isNew` becomes
    # false, and we need to set the id in the URL when we transition to the
    # result route.)
    search.addObserver('id', @, @_sendShowResultEvent)
    search.get('transaction').commit()


  _sendShowResultEvent: ->
    search = @get('currentSearch')

    if search.get('id')
      @get('target').send 'showResult',
                          corpus: @get('corpus')
                          search: search
                          pageNo: 1

      search.removeObserver('id', @, @_sendShowResultEvent)
