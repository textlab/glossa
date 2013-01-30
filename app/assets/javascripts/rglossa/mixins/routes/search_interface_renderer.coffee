# Mixed into routes that render a search interface
App.SearchInterfaceRenderer = Em.Mixin.create

  # Selects which search interface to show inside the template.
  # App.CorpusController determines the appropriate interface depending on the
  # current corpus (or picks the default). The argument is either 'home' or
  # 'result' depending on whether we should render the home page for the
  # corpus or the search results page.
  renderSearchInterface: (mainTemplate) ->
    searchEngine = @controllerFor('corpus').get('searchEngine')
    mainTemplate = "#{searchEngine}/#{mainTemplate}"
    searchInputsTemplate = "#{searchEngine}/search_inputs"

    @render(mainTemplate)

    @render searchInputsTemplate,
      into: mainTemplate
      outlet: 'searchInputs'
      controller: 'searches'
