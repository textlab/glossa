App.Adapter = DS.RESTAdapter.extend
  plurals:
    corpus:     'corpora'
    search:     'searches'
    cwb_search: 'cwb_searches'

  mappings:
    metadata_categories: 'App.MetadataCategory'
    metadata_values: 'App.MetadataValue'