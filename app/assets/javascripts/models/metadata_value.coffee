App.MetadataValue = DS.Model.extend
  text: DS.attr('string')

  metadataCategory: DS.belongsTo('App.MetadataCategory')
