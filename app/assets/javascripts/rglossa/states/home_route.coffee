# This route fetches the corpus with the given short name and dispatches
# to the appropriate search interface based on the searchType that is set
# on the corpus (or to a CWB interface if none is specified)
App.HomeRoute = Em.Route.extend

  model: (params) ->
    corpus = @controllerFor('corpus').setCorpus(params['corpus_short_name'])

  redirect: (corpus) ->
    # Choose which search interface to display based on the search type
    # for this corpus
    searchType = @controllerFor('corpus').get('searchType')
    newRoute = switch searchType
      when 'cwb' then 'cwb.regex'

      # Add routes for other search interfaces/engines here as they are
      # implemented, e.g.
      # when 'corpuscle' then 'corpuscleSimple'
      # when 'annis2' then 'annis2Simple'

    @transitionTo(newRoute, corpus)
