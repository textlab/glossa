App.ResultRowController = Em.ObjectController.extend
  needs: ['corpus']
  corpusHasSound: null
  corpusHasSoundBinding: 'controllers.corpus.content.hasSound'
  corpusExtraLineAttrs: null
  corpusExtraLineAttrsBinding: 'controllers.corpus.content.extraLineAttrs'

  _isShowingSound: false

  isShowingSound: ((key, value)->
    if value?
      @set('_isShowingSound', value)
    @get('_isShowingSound')
  ).property()

  toggleJplayer: ->
    @set('isShowingSound', not @get('isShowingSound'))

  extraLine: (->
    match = (value for key, value of @get('mediaObj.divs.annotation') when value.is_match)[0]
    (value.orig for key, value of match.line).join(' ')
  ).property()