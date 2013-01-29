App.CorpusResultsRoute = Em.Route.extend App.SearchInterfaceRenderer,

  # These probably belong more in setupController(), but that method doesn't
  # get the params argument
  model: (params) ->
    # Get the search model subclass for the search engine used by the current
    # corpus and find the record with the given search_id
    searchModelClass = @controllerFor('corpus').get('searchModelClass')
    search = searchModelClass.find(params['search_id'])

    resultPage = search.getResultPage(params['page_no'])
    @controllerFor('resultToolbar').set('content', resultPage)


  renderTemplate: ->
    # Render the results template into the main outlet of the corpus template
    @_super()

    template = 'corpus/results'
    @renderSearchInterfaceInto(template)

    @render 'results/toolbar', into: template, outlet: 'resultsToolbar'

    # @render 'cwbResults',    outlet: 'results'

  events:
    changeResultPage: -> @transitionTo('changingResultPage')
