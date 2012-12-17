App.Search = DS.Model.extend
  metadataValueIds: DS.attr('hash')
  queries: DS.attr('array')

  # Non-persisted attribute: cache of search result pages. Will be initialized
  # by the adapter to an Em.Object containing the first two result pages after
  # the search object is created
  resultPages: null

  getResultPage: (pageNo) ->
    if pageNo of @resultPages
      @resultPages[pageNo]
    else
      page = @_loadResultPage(pageNo)
      @resultPages[pageNo] = page

  # private
  _loadResultPage: (pageNo) ->
    adapter = App.store.adapter
    type = @constructor
    root = adapter.rootForType(type)
    url = adapter.buildURL(root, @get('id')) + "/results?pages[]=#{pageNo}"

    adapter.ajax url, 'GET',
      success: (data) =>
        @get('resultPages').set(pageNo, data.search_results.pages[pageNo])