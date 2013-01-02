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
    # @connectControllers()

  connectControllers: ->
    Em.controllerFor('metadataAccordion').connectControllers('corpus')

    # Connect controllers for different kind of searches as well as result
    # handling controllers to the controller proxying the currently active
    # search and results. Also give the controller for the array of searches
    # access to the controller for the current corpus. For CWB:
    Em.controllerFor('cwbSimpleSearch').connectControllers('search')
    Em.controllerFor('cwbRegexSearch').connectControllers('search')
    Em.controllerFor('cwbResults').connectControllers('resultToolbar')
    Em.controllerFor('resultToolbar').connectControllers('search')

    Em.controllerFor('cwbSearches').connectControllers('corpus')
