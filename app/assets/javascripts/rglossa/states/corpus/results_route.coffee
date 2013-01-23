App.CorpusResultsRoute = Em.Route.extend

  # These probably belong more in setupController(), but that method doesn't
  # get the params argument
  model: (params) ->
    # Get the search model subclass for the search engine used by the current
    # corpus and find the record with the given search_id
    searchModelClass = App.get(@controllerFor('corpus').get('searchModelClass'))
    search = searchModelClass.find(params['search_id'])

    resultPage = search.getResultPage(params['page_no'])
    @controllerFor('resultToolbar').set('content', resultPage)


  renderTemplate: ->
    # Render the results template into the main outlet of the corpus template
    @_super()

    template = 'corpus/results'

    # Select which search interface to show inside the results template
    # itself. App.CorpusController determines the appropriate interface
    # depending on the current corpus (or picks the default)
    searchInterface = @controllerFor('corpus').get('searchInterfaceTemplate')
    @render searchInterface, into: template, outlet: 'searchInterface'

    @render 'results/toolbar', into: template, outlet: 'resultsToolbar'

    # @render 'cwbResults',    outlet: 'results'

  events:
    changeResultPage: -> @transitionTo('changingResultPage')
