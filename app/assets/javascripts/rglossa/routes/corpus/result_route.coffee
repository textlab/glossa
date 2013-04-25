App.CorpusResultRoute = Em.Route.extend

  model: (params) ->
    {search_id: searchId, page_no: @pageNo} = params

    # Get the search model subclass for the search engine used by the current
    # corpus and find the record with the given search_id
    searchModelClass = @controllerFor('corpus').get('searchModelClass')
    search = searchModelClass.find(searchId)
    @controllerFor('search').set('model', search)

    search


  serialize: (params) ->
    [search, @pageNo] = params
    {search_id: search.get('id'), page_no: @pageNo}


  setupController: (controller, model) ->
    # When the route is loaded via a URL, `model` is the actual search model, but when we
    # transition here from a different route, the "model" is actually an array containing the model
    # and the page number...
    model = model[0] if Em.isArray(model)
    @controllerFor('resultTable').set('content', model.getResultPage(@pageNo))


  renderTemplate: ->
    searchEngine = @controllerFor('corpus').get('searchEngine')
    @render("#{searchEngine}/result")
    $('#new-search-button').show()

