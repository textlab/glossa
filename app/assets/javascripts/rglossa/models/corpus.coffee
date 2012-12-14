App.Corpus = DS.Model.extend
  name: DS.attr('string')
  shortName: DS.attr('string')

  metadataCategories: DS.hasMany('App.MetadataCategory')