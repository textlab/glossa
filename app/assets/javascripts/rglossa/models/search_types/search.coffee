defaultMaxHits = 2000

App.Search = DS.Model.extend
  metadataValueIds:  DS.attr('hash')
  queries:           DS.attr('queries')
  numHits:           DS.attr('number', defaultValue: 0)
  maxHits:           DS.attr('number', defaultValue: defaultMaxHits)

  # Non-persisted attribute: cache of search result pages. Will be initialized
  # by the adapter to an Em.Object containing the first two result pages after
  # the search object is created
  resultPages: null

  setupResultPages: (json) ->
    # When we create any kind of search model, the server will include the
    # first two result pages as part of its JSON response so that we don't
    # have to send a separate request in order to get them.
    #
    # Note: We cannot use the didCreate model hook for this because that
    # method doesn't receive the JSON (only the model itself).
    @resultPages = Em.Object.create(
      1: json['first_two_result_pages']['1']
      2: json['first_two_result_pages']['2']
    )

    # For corpora that contain several parts (i.e. either for performance
    # reasons or because it is a "metacorpus" containing several other
    # corpora) we need to keep track of which part the latest search results
    # came from
    @currentCorpusPart = json['current_corpus_part']


  getResultPage: (pageNo) ->
    pageNo = pageNo + ''

    unless pageNo of @resultPages
      @_loadResultPage(pageNo)
      @get('resultPages').set(pageNo, [])

    @resultPages.get(pageNo)


  # private
  _loadResultPage: (pageNo) ->
    type      = @constructor
    adapter   = @get('store').adapterForType(type)
    root      = adapter.rootForType(type)
    url       = adapter.buildURL(root, @get('id')) +
      "/results?pages[]=#{pageNo}&current_corpus_part=#{@currentCorpusPart}"

    adapter.ajax(url, 'GET').then (data) =>
      @get('resultPages').get(pageNo).setObjects(data.search_results.pages[pageNo])
