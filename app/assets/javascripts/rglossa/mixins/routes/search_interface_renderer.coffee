# Mixed into routes that render a search interface
App.SearchInterfaceRenderer = Em.Mixin.create

  renderSearchInterfaceInto: (template) ->
    # Select which search interface to show inside the template.
    # App.CorpusController determines the appropriate interface depending on
    # the current corpus (or picks the default)
    corpusController         = @controllerFor('corpus')
    searchInterface          = corpusController.get('searchInterfaceTemplate')

    @render searchInterface,
      into: template
      outlet: 'searchInterface'
      controller: 'searches'
