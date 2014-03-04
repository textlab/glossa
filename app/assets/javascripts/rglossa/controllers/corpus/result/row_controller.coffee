App.ResultRowController = Em.ObjectController.extend
  needs: ['corpus']
  corpusHasSound: null
  corpusHasSoundBinding: 'controllers.corpus.content.hasSound'

  _isShowingSound: false

  isShowingSound: ((key, value)->
    if value?
      @set('_isShowingSound', value)
    @get('_isShowingSound')
  ).property()

  showJplayer: ->
    @set('isShowingSound', true)