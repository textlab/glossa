App.SearchResultsRoute = Em.Route.extend

  setupControllers: (controller, params) ->
    search = App.CwbSearch.find(params['cwb_search_id'])
    Em.controllerFor('search').set('content', search)

    resultPage = search.getResultPage(params['page_no'])
    Em.controllerFor('resultToolbar').set('content', resultPage)


  renderTemplates: ->
    @render 'resultToolbar', outlet: 'resultToolbar'
    @render 'cwbResults',    outlet: 'results'

  #########
  # Events
  #########

  changeResultPage: -> @transitionTo('changingResultPage')
