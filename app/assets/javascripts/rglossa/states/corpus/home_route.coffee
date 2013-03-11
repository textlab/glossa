App.CorpusHomeRoute = Em.Route.extend

  renderTemplate: ->
    searchEngine = @controllerFor('corpus').get('searchEngine')
    @render("#{searchEngine}/home")
