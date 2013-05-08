App.CwbSearchInputsController = Em.Controller.extend

  needs: ['corpus', 'searches']

  # This will be bound to properties on views for simple search, multiword
  # search and regex search.
  query: ''

  corpusShortNameBinding: 'controllers.corpus.model.shortName'

  currentInterface: null

  isShowingSimple: (->
    @get('currentInterface') is 'simple'
  ).property('currentInterface').volatile()

  isShowingMultiword: (->
    @get('currentInterface') is 'multiword'
  ).property('currentInterface')

  isShowingRegex: (->
    @get('currentInterface') is 'regex'
  ).property('currentInterface')

  # Actions
  showSimple:    -> @set('currentInterface', 'simple')
  showMultiword: -> @set('currentInterface', 'multiword')
  showRegex:     -> @set('currentInterface', 'regex')

  init: ->
    # Show the preferred interface (simple, multiword or regex) for this user or corpus
    @set('currentInterface', @get('controllers.corpus.preferredSearchInterfaceVariant'))

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
