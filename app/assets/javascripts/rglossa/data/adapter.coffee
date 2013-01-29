DS.RESTAdapter.configure 'plurals',
  corpus:     'corpora'
  search:     'searches'
  cwb_search: 'cwb_searches'

DS.RESTAdapter.configure 'App.MetadataCategory',
  sideloadAs: 'metadata_categories'

DS.RESTAdapter.configure 'App.MetadataValue',
  sideloadAs: 'metadata_values'


App.Adapter = DS.RESTAdapter.extend

  buildURL: (record, suffix) ->
    url = @_super(record, suffix)
    url = "/search_engines#{url}" unless record.search(/_search$/) is -1
    url


  didCreateRecord: (store, type, record, json) ->
    @_super(store, type, record, json)

    if type.superclass is App.Search
      # When we create any kind of search model, the server will include
      # the first result page as part of its JSON response so that we don't
      # have to send a separate request in order to get that.
      #
      # Note: We cannot use the didCreate model hook for this because that
      # method doesn't receive the JSON (only the model itself).
      root = @rootForType(type)
      record.resultPages = Em.Object.create({
        1: json[root]['first_two_result_pages']['1']
        2: json[root]['first_two_result_pages']['2']})


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
