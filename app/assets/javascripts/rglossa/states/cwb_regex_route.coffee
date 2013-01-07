App.CwbRegexRoute = Em.Route.extend

  setupControllers: (controller, model) ->
    # Now that we know we will use the regex interface, connect its
    # controller to the controller handling CWB searches
    Em.controllerFor('cwbSearches').set('searchTypeController', controller)

  renderTemplates: ->
    @render 'corpusInfo',
      outlet: 'corpusInfo'
      controller: 'corpusController'

    @render 'cwbRegex',
      outlet: 'search'

  exit: ->
    @render null,
      outlet: 'corpusInfo'

  events:
    search: -> @transitionTo('searching')

  #########################
  # Non-routable substates
  #########################

  searching: Em.State.create

    enter: ->
      # TODO: Show spinner while we are searching
      Em.controllerFor('cwbSearches').createCwbSearch()
      App.store.commit()

    #########
    # Events
    #########

    showResults: -> @transitionTo('searchResults')
