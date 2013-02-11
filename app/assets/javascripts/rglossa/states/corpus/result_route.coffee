App.CorpusResultRoute = Em.Route.extend App.SearchInterfaceRenderer,

  # These probably belong more in setupController(), but that method doesn't
  # get the params argument
  model: (params) ->
    # Get the search model subclass for the search engine used by the current
    # corpus and find the record with the given search_id
    searchModelClass = @controllerFor('corpus').get('searchModelClass')
    search = searchModelClass.find(params['search_id'])
    @controllerFor('search').set('model', search)

    resultPage = search.getResultPage(params['page_no'] - 1)
    @controllerFor('resultPage').set('content', resultPage)


  serialize: (params) ->
    [@search, @pageNo] = params
    {search_id: @search.get('id'), page_no: @pageNo}


  setupController: ->
    @controllerFor('resultTable').set('content', @search.getResultPage(@pageNo))

  renderTemplate: ->
    @renderSearchInterface('result')
