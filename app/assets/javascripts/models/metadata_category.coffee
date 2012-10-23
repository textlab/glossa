App.MetadataCategory = DS.Model.extend
  corpus: DS.belongsTo('App.Corpus')

  localizedName: DS.attr('string')

  metadataValues: DS.hasMany('App.MetadataValue')

  collapsibleId: (->
    "collapse-#{@get 'localizedName'}"
  ).property()

  collapsibleHref: (->
    "##{@get 'collapsibleId'}"
  ).property()