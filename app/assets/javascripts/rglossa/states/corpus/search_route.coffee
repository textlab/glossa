# This route sets up everything that is common to the search front page and
# result pages, e.g. the metadata accordion in the sidebar etc.
App.CorpusSearchRoute = Em.Route.extend

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
