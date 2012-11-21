# Represents a single page of search results from the Corpus Workbench.

App.CwbSearchResultPage = DS.model.extend
  results: DS.hasMany('App.CwbSearchResult')