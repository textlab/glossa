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
    url = "/search_types#{url}" unless record.search(/_search$/) is -1
    url


  didCreateRecord: (store, type, record, json) ->
    @_super(store, type, record, json)

    if type.superclass is App.Search
      # When we create any kind of search model, the server will include
      # the first result page as part of its JSON response so that we don't
      # have to send a separate request in order to get that.
      root = @rootForType(type)
      record.set('resultPages', {1: json[root]['first_result_page']})