App.CwbSearchInputsController = Em.Controller.extend

  needs: ['corpus', 'searches']

  # This will be bound to properties on views for for simple search, multiword
  # search and regex search.
  query: ''

  corpusShortNameBinding: 'controllers.corpus.model.shortName'

  # Action handler
  search: ->
    # TODO: Add support for simultaneous search in different "editions" within
    # the same corpus (e.g. different languages in a parallel corpus). Each
    # edition will have a distinct shortName.
    queries = [
      corpusEdition: @get('corpusShortName').toUpperCase()
      query:         @get('query')
    ]
    @get('controllers.searches').createSearch('CwbSearch', queries)
