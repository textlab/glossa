App.SearchResultsRoute = Em.Route.extend

  setupController: (controller, params) ->
    search = App.CwbSearch.find(params['cwb_search_id'])
    @controllerFor('search').set('content', search)

    resultPage = search.getResultPage(params['page_no'])
    @controllerFor('resultToolbar').set('content', resultPage)


  renderTemplate: ->
    @render 'resultToolbar', outlet: 'resultToolbar'
    @render 'cwbResults',    outlet: 'results'

  events:
    changeResultPage: -> @transitionTo('changingResultPage')
