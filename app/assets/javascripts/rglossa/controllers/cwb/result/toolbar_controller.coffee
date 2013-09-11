#= require rglossa/controllers/corpus/result/toolbar_controller

App.CwbResultToolbarController = App.ResultToolbarController.extend
  needs: ['cwbSearchInputs', 'corpusResult']

  # action handlers

  showStatistics: ->
    query = @get('controllers.cwbSearchInputs.firstObject')
    namespace = DS.RESTAdapter.prototype.namespace
    req = $.getJSON 'r/search_engines/cwb/query_freq',
      { query: query.query, corpus: query.corpusShortName }

    req.done (data) =>
      @set('controllers.corpusResult.content', data.pairs)
      $('#frequencies-modal').modal()