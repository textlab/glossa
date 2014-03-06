App.Corpus = DS.Model.extend
  name: DS.attr('string')
  logo: DS.attr('string')
  shortName: DS.attr('string')
  langs: DS.attr('array')
  displayAttrs: DS.attr('array')
  extraLineAttrs: DS.attr('array')
  parts: DS.attr('array')
  searchEngine: DS.attr('string')
  hasSound: DS.attr('boolean')

  metadataCategories: DS.hasMany('App.MetadataCategory')
