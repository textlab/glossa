#= require ./core
#= require_tree ./data
#= require_tree ./models
#= require_tree ./controllers
#= require_tree ./views
#= require_tree ./helpers
#= require_tree ./templates
#= require_tree ./states

App.reopen
  ready: ->
    @connectControllers()

  connectControllers: ->
    App.get('router.metadataAccordionController').connectControllers(
      'selectedCorpus')

    # Connect controllers for different kind of searches as well as result
    # handling controllers to the controller proxying the currently active
    # search and results. Also give the controller for the array of searches
    # access to the controller for the current corpus. For CWB:
    App.get('router.cwbSimpleSearchController').connectControllers(
      'currentSearch')
    App.get('router.cwbRegexSearchController').connectControllers(
      'currentSearch')
    App.get('router.cwbResultsController').connectControllers(
      'resultToolbar')
    App.get('router.resultToolbarController').connectControllers(
      'currentSearch')

    App.get('router.cwbSearchesController').connectControllers(
      'selectedCorpus')
