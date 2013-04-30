App.CorpusHomeRoute = Em.Route.extend

  renderTemplate: ->
    searchEngine = @controllerFor('corpus').get('searchEngine')
    @render("#{searchEngine}/home")
    $('#new-search-button').hide()

    # We are starting a new search, so remove all metadata selections. The first time we come
    # here, the metadata selects won't be rendered yet, so we won't find any, but then it
    # doesn't matter anyway.
    $('input[type="hidden"][data-metadata-selection]').each (index, elm) ->
      view = Em.View.views[$(elm).attr('id')]
      view.closeSelect()
      true
