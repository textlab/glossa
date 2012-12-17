App.Adapter = DS.RESTAdapter.extend
  plurals:
    corpus:     'corpora'
    search:     'searches'
    cwb_search: 'cwb_searches'

  mappings:
    metadata_categories: 'App.MetadataCategory'
    metadata_values: 'App.MetadataValue'


  buildURL: (record, suffix) ->
    url = @_super(record, suffix)
    url = "/search_types#{url}" unless record.search(/_search$/) is -1
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

      # When the search has been created and we have got an ID from the
      # server, we transition to the *results* route with the record ID and
      # the first result page as parameters.
      #
      # This would also be more natural to do in the didCreate model hook, but
      # due to a bug in Ember Data, that hook is called before the ID received
      # from the server is set on the record. So until that is fixed, we do it
      # here instead.
      App.router.transitionTo('results', {
        cwb_search_id: record.get('id')
        page_no: 1 })


# Arrays and hashes should just be passed along to be (de)serialized by the
# standard mechanisms. Ember Data does not include these attribute types (yet)
# because of complications wrt knowing when an attribute becomes dirty, but we
# define them ourselves and just make sure to dirty the object ourselves when
# needed.
App.Adapter.registerTransform 'array',
  fromData: (serialized) ->
    serialized

  toData: (deserialized) ->
    deserialized

App.Adapter.registerTransform 'hash',
  fromData: (serialized) ->
    serialized

  toData: (deserialized) ->
    deserialized
