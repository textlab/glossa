App.MetadataValue = DS.Model.extend
  cateory: DS.belongsTo('App.MetadataCategory')

  text_value: DS.attr('string')