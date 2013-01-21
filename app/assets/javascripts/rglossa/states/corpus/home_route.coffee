# This route dispatches to the appropriate search interface based on the
# searchEngine that is set on the corpus (or to a CWB interface if none is
# specified)
App.CorpusHomeRoute = Em.Route.extend

  redirect: ->
    # Choose which search interface to display based on the search type for
    # the selected corpus. The corpusController determines the search type
    # from its model (i.e. the corpus), and the corpus is fetched as the model
    # of the parent route (CorpusRoute). In fact, we don't get here until
    # Ember has finished loading the parent route model from the server, so we
    # don't need to set up an observer to wait for it or anything :-)
    searchEngine = @controllerFor('corpus').get('searchEngine')
    newRoute = switch searchEngine
      when 'cwb' then 'cwb.regex'

      # Add routes for other search interfaces/engines here as they are
      # implemented, e.g.
      # when 'corpuscle' then 'corpuscleSimple'
      # when 'annis2' then 'annis2Simple'

    @transitionTo(newRoute)
