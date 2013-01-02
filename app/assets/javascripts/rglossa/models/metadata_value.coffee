App.MetadataValue = DS.Model.extend
  text: DS.attr('string')

  metadataCategory: DS.belongsTo('App.MetadataCategory')


App.store.adapter.serializer.configure App.MetadataValue,
  sideloadAs: 'metadata_values'
