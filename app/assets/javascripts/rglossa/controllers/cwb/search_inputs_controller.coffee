App.CwbSearchInputsController = Em.ArrayController.extend
  needs: ['corpus', 'searches']

  corpusBinding: 'controllers.corpus.content'

  currentInterface: null

  init: ->
    # Show the preferred interface (simple, multiword or regex) for this user or corpus
    @set('currentInterface', @get('controllers.corpus.preferredSearchInterfaceVariant'))

    tags = @get('corpus.langs.firstObject.tags')
    @set 'content', [
      query: '',
      corpusShortName: @get('corpus.shortName'),
      posAttr: tags?.attr,
      tags: tags?.options
    ]

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


  search: (component, options = {}) ->
    options.queries = @get('content')
    @get('controllers.searches').createSearch('CwbSearch', options)
