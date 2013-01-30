App.CorpusHomeRoute = Em.Route.extend App.SearchInterfaceRenderer,

  renderTemplate: ->
    # Render the home template into the main outlet of the corpus template
    @_super()
    @renderSearchInterfaceInto('corpus/home')
