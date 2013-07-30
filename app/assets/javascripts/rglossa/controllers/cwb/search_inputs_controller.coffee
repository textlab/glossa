App.CwbSearchInputsController = Em.Controller.extend

  needs: ['corpus', 'searches']

  # This will be bound to properties on controllers for simple search, multiword
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

  init: ->
    # Show the preferred interface (simple, multiword or regex) for this user or corpus
    @set('currentInterface', @get('controllers.corpus.preferredSearchInterfaceVariant'))


  # Action handlers
  showSimple:    -> @set('currentInterface', 'simple')
  showMultiword: -> @set('currentInterface', 'multiword')
  showRegex:     -> @set('currentInterface', 'regex')

  addWord: ->
    query = @get('query')
    return unless query

    query += ' ""'
    @set('query', query)


  search: (options = {}) ->
    # TODO: Add support for simultaneous search in different "editions" within
    # the same corpus (e.g. different languages in a parallel corpus). Each
    # edition will have a distinct shortName.
    options.queries = [
      corpusEdition: @get('corpusShortName').toUpperCase()
      query:         @get('query')
    ]
    @get('controllers.searches').createSearch('CwbSearch', options)
