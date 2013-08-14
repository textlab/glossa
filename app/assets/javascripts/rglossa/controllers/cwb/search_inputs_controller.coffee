App.CwbSearchInputsController = Em.ArrayController.extend
  needs: ['corpus', 'searches']

  currentInterface: null

  init: ->
    # Show the preferred interface (simple, multiword or regex) for this user or corpus
    @set('currentInterface', @get('controllers.corpus.preferredSearchInterfaceVariant'))
    @set('content', [Em.Object.create({query: '', corpusShortName: 'BOKMAL'})])

  isShowingSimple: (->
    @get('currentInterface') is 'simple'
  ).property('currentInterface').volatile()

  isShowingMultiword: (->
    @get('currentInterface') is 'multiword'
  ).property('currentInterface')

  isShowingRegex: (->
    @get('currentInterface') is 'regex'
  ).property('currentInterface')


  # Action handlers
  showSimple:    -> @set('currentInterface', 'simple')
  showMultiword: -> @set('currentInterface', 'multiword')
  showRegex:     -> @set('currentInterface', 'regex')


  addWord: ->
    query = @get('content')
    return unless query

    query += ' ""'
    @set('content', query)


  search: (component, options = {}) ->
    options.queries = @get('content')
    @get('controllers.searches').createSearch('CwbSearch', options)
