#= require ./store
#= require_tree ./models
#= require_tree ./controllers
#= require_tree ./views
#= require_tree ./helpers
#= require_tree ./templates
#= require_tree ./routes
#= require_self

router = App.router = App.Router.create
  location: 'hash'

App.initialize(router)

