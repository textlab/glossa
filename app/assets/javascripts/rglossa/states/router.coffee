# NOTE: The class name of routes need to be prefixed with the name of their
# parent, while resources should not (cf.
# https://github.com/emberjs/ember.js/commit/
# e4af09edd357cdccfddfa684247bc43a6eaae0fe#commitcomment-2432875). So, it
# should be App.CorpusSearchRoute for the 'search' route, but App.CorpusRoute
# for the 'corpus' resource.
App.Router.map (match) ->

  # fetches the corpus and sets up everything that is common to the search
  # page and the result pages, e.g. the metadata accordion in the sidebar etc.
  @resource 'corpus', path: 'corp/:corpus_short_name', ->

    @route 'home'

    # the search results page, which also allows further searches
    @route 'results', path: 'res/:search_id/:page_no'



# Mixed into routes that render a search interface
App.SearchInterfaceRenderer = Em.Mixin.create

  renderSearchInterfaceInto: (template) ->
    # Select which search interface to show inside the template.
    # App.CorpusController determines the appropriate interface depending on
    # the current corpus (or picks the default)
    corpusController         = @controllerFor('corpus')
    searchesControllerPrefix = corpusController.get('searchesControllerPrefix')
    searchInterface          = corpusController.get('searchInterfaceTemplate')

    @render searchInterface,
      into: template
      outlet: 'searchInterface'
      controller: searchesControllerPrefix

