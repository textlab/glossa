App.Adapter = DS.RESTAdapter.extend
  plurals:
    corpus: 'corpora'

  mappings:
    metadata_categories: 'App.MetadataCategory'
    metadata_values: 'App.MetadataValue'