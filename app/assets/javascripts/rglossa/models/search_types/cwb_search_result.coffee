# Represent a single search result ("hit") in the Corpus Workbench.

App.CwbSearchResult = DS.Model.extend
  leftContext:  DS.attr('string')
  match:        DS.attr('string')
  rightContext: DS.attr('string')
