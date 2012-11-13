#= require ./core
#= require_tree ./data/
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
    App.get('router.metadataAccordionController').connectControllers('selectedCorpus')
