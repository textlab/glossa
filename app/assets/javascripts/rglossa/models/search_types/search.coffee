App.Search = DS.Model.extend
  metadataValueIds: DS.attr('hash')
  queries: DS.attr('array')

  # non-persisted attribute: cache of search result pages
  resultPages: {}

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

    adapter.ajax(url, 'GET', {})