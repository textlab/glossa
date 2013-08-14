App.SearchesController = Em.ArrayController.extend

  currentSearch: null

  needs: ['corpus', 'corpusMetadataCategory']

  corpus: null
  corpusBinding: 'controllers.corpus.model'

  createSearch: (searchModel, {queries, maxHits}) ->
    debugger
    # Empty queries are not allowed
    return unless queries.some (query) ->
      query.query isnt ''

    metadataValueIds = @get('controllers.corpusMetadataCategory').collectMetadataValues()

    params =
      metadataValueIds: metadataValueIds
      queries: queries
    if maxHits
      # -1 means no limit, which means we must set null explicitly in the call
      # to createRecord in order to prevent the default limit to be set
      params.maxHits = if maxHits is -1 then null else maxHits

    search = App.get(searchModel).createRecord(params)

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

    # Hide any previous results and show spinners while we are waiting for results
    $('.search-result-toolbar, .search-result-table-container').hide()
    $('.result-spinner').show()


  _sendShowResultEvent: ->
    search = @get('currentSearch')

    if search.get('id')
      @get('target').send 'showResult',
                          corpus: @get('corpus')
                          search: search
                          pageNo: 1

      search.removeObserver('id', @, @_sendShowResultEvent)

      # Hide spinners and show new search results
      $('.result-spinner').hide()
      $('.search-result-toolbar, .search-result-table-container').show()

