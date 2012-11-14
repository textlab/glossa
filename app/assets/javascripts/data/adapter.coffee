App.Adapter = DS.RESTAdapter.extend
  plurals:
    corpus: 'corpora'
    search: 'searches'

  mappings:
    metadata_categories: 'App.MetadataCategory'
    metadata_values: 'App.MetadataValue'