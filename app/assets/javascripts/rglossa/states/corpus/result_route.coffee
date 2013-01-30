App.CorpusResultRoute = Em.Route.extend App.SearchInterfaceRenderer,

  # These probably belong more in setupController(), but that method doesn't
  # get the params argument
  model: (params) ->
    # Get the search model subclass for the search engine used by the current
    # corpus and find the record with the given search_id
    searchModelClass = @controllerFor('corpus').get('searchModelClass')
    search = searchModelClass.find(params['search_id'])
    @controllerFor('search').set('model', search)

    resultPage = search.getResultPage(params['page_no'])
    @controllerFor('resultPage').set('content', resultPage)


  serialize: (params) ->
    [search, pageNo] = params
    {search_id: search.get('id'), page_no: pageNo}


  renderTemplate: ->
    # Render the result template into the main outlet of the corpus template
    @_super()

    template = 'corpus/result'
    @renderSearchInterfaceInto(template)

    @render 'result/toolbar', into: template, outlet: 'resultToolbar'

    @render 'result/page', into: template, outlet: 'resultPage'


  events:
    changeResultPage: (pageNo) -> @transitionTo('corpus.result')
