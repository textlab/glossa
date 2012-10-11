#= require ./core
#= require_tree ./data/
#= require_tree ./models
#= require_tree ./controllers
#= require_tree ./views
#= require_tree ./helpers
#= require_tree ./templates
#= require_tree ./states

App.ready = ->
  App.Corpus.find(1)
