App.SearchRoute = Em.Route.extend

  renderTemplates: ->
    # Metadata selection is independent of the type of search interface, so
    # render the metadata accordion in the sidebar for all search interfaces.
    # The rest of the search interface will be rendered by a substate that is
    # determined by the desired search type (CWB, Corpuscle etc.)
    @render 'metadataAccordion', outlet: 'leftSidebar'

  #########################
  # Non-routable substates
  #########################

  # When we go from one page of search results to the next, we need to
  # traverse out of the searchResults state and re-enter it in order to set
  # the new page number in the URL. Hence we got to this non-routable state,
  # which simply redirects back to the searchResults state with new
  # parameters.
  changingResultPage: Em.State.create

    redirect: ->
      params =
        cwb_search_id: router.get('searchController.id')
        page_no: router.get('resultToolbarController.currentPageNo') + 1

      @transitionTo('searchResults', params)
