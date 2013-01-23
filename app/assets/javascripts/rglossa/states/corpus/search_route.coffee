# This route sets up everything that is common to the search front page and
# result pages, e.g. the metadata accordion in the sidebar etc.
App.CorpusSearchRoute = Em.Route.extend

  renderTemplate: ->
    # Render the search template into the main outlet of the corpus template
    @_super()

    # Select which search interface to show inside the search template itself.
    # App.CorpusController determines the appropriate interface depending on
    # the current corpus (or picks the default)
    corpusController         = @controllerFor('corpus')
    searchesControllerPrefix = corpusController.get('searchesControllerPrefix')
    searchInterface          = corpusController.get('searchInterfaceTemplate')

    @render searchInterface,
      into: 'corpus/search'
      outlet: 'searchInterface'
      controller: searchesControllerPrefix

  #########################
  # Non-routable substates
  #########################

  # When we go from one page of search results to the next, we need to
  # traverse out of the search.results state and re-enter it in order to set
  # the new page number in the URL. Hence we got to this non-routable state,
  # which simply redirects back to the search.results state with new
  # parameters.
  changingResultPage: Em.State.create

    redirect: ->
      params =
        cwb_search_id: router.get('searchController.id')
        page_no: router.get('resultToolbarController.currentPageNo') + 1

      @transitionTo('search.results', params)
