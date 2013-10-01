DS.RESTAdapter.configure 'plurals',
  corpus:     'corpora'
  search:     'searches'
  cwb_search: 'cwb_searches'
  metadata_category: 'metadata_categories'

App.Adapter = DS.RESTAdapter.extend

  buildURL: (record, suffix) ->
    url = @_super(record, suffix)
    unless record.search(/_search$/) is -1
      namespace = DS.RESTAdapter.prototype.namespace
      if namespace
        url = url.replace(namespace, namespace + '/search_engines')
      else
        url = "/search_engines#{url}"
    url


  didCreateRecord: (store, type, record, json) ->
    @_super(store, type, record, json)

    if record.setupResultPages?
      root = @rootForType(type)
      record.setupResultPages(json[root])


  didFindRecord: (store, type, payload, id) ->
    @_super(store, type, payload, id)

    record = type.find(id)
    if record.setupResultPages?
      root = @rootForType(type)
      record.setupResultPages(payload[root])

# Arrays and hashes should just be passed along to be (de)serialized by the
# standard mechanisms. Ember Data does not include these attribute types (yet)
# because of complications wrt knowing when an attribute becomes dirty, but we
# define them ourselves and just make sure to dirty the object ourselves when
# needed.
App.Adapter.registerTransform 'array',
  deserialize: (serialized) ->
    serialized

  serialize: (deserialized) ->
    deserialized

App.Adapter.registerTransform 'hash',
  deserialize: (serialized) ->
    serialized

  serialize: (deserialized) ->
    deserialized

App.Adapter.registerTransform 'queries',
  deserialize: (serialized) ->
    serialized

  serialize: (deserialized) ->
    deserialized.map (querySpec) ->
      query: querySpec.query
      corpusShortName: querySpec.corpusShortName
