# Represents a single page of search results from the Corpus Workbench.
# Inherits from App.SearchResultPage.

App.CwbSearchResultPage = App.SearchResultPage.extend
  results: DS.hasMany('App.CwbSearchResult')