# Represent a single search result ("hit") in the Corpus Workbench.
# Inherits from App.SearchResult.

App.CwbSearchResult = App.SearchResult.extend
  leftContext:  DS.attr('string')
  match:        DS.attr('string')
  rightContext: DS.attr('string')

  page: DS.belongsTo('App.CwbSearchResultPage')