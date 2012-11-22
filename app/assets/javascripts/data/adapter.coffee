App.Adapter = DS.RESTAdapter.extend
  plurals:
    corpus:     'corpora'
    search:     'searches'
    cwb_search: 'cwb_searches'

  mappings:
    metadata_categories: 'App.MetadataCategory'
    metadata_values: 'App.MetadataValue'


  buildURL: (record, suffix) ->
    url = @_super(record, suffix)
    url = "/search_types/#{url}" unless record.search(/_search$/) is -1
    url
