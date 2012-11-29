App.Corpus = DS.Model.extend
  name: DS.attr('string')

  metadataCategories: DS.hasMany('App.MetadataCategory')