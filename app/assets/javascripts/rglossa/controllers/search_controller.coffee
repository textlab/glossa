App.SearchController = Em.ObjectController.extend
  needs: ['searches', 'corpus']

  model: null
  modelBinding: 'controllers.searches.currentSearch'

  corpus: null
  corpusBinding: 'controllers.corpus.model'

  modelIdDidChange: (->
    # When the search has been created and we have got an ID from the server,
    # we ask the router to transition to the results route with the model ID
    # and the first result page as parameters.
    #
    # It would be more natural to listen to the didCreate event or observe the
    # isNew status, but due to a bug in Ember Data, both of these happen
    # before the ID received from the server is set on the record. So at least
    # until that is fixed, we observe the model ID.
    if @get('model.id')
      @get('target').send 'showResults',
        corpus: @get('corpus')
        search: @get('model')
        pageNo: 1
  ).observes('model.id')