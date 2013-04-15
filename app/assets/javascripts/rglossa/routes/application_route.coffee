App.ApplicationRoute = Em.Route.extend

  setupController: ->
    # Force Ember to instantiate controllers to make bindings work from the
    # start
    @controllerFor('search')
