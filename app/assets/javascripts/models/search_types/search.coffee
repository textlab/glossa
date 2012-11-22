App.Search = DS.Model.extend
  queries: DS.attr('string')

  # non-persisted attribute: cache of search result pages
  resultPages: {}

  getResultPage: (pageNo) ->
    if pageNo of own resultPages
      resultPages[pageNo]
    else
      page = @_loadResultPage(pageNo)
      resultPages[pageNo] = page

  # private
  _loadResultPage: (pageNo) ->
