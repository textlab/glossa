App.MetadataCategory = DS.Model.extend

  name: DS.attr('string')

  corpus: DS.belongsTo('App.Corpus')
  metadataValues: DS.hasMany('App.MetadataValue')

  collapsibleId: (->
    "collapse-#{@get 'name'}"
  ).property()

  collapsibleHref: (->
    "##{@get 'collapsibleId'}"
  ).property()


App.store.adapter.serializer.configure App.MetadataCategory,
  sideloadAs: 'metadata_categories'
