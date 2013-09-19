App.CorpusRoute = Em.Route.extend

  model: (params) ->
    App.Corpus.find(params['corpus_short_name'])

  serialize: (params) ->
    {corpus_short_name: params.get('id')}


  events:
    showResult: (params) ->
      {corpus, search, pageNo} = params
      @transitionTo('corpus.result', corpus, [search, pageNo])


    showCorpusHome: ->
      # FIXME: Should we just do this for all input controllers or find another solution?
      tags = @currentModel.get('langs.firstObject.tags')
      @controllerFor('cwbSearchInputs').set('content', [{
        query: '',
        corpusShortName: @currentModel.get('shortName'),
        posAttr: tags.attr,
        tags: tags.options
      }])

      @transitionTo("corpus.home")


    metadataSelectionsChanged: ->
      # If we get here, it means that we are currently in a route that should not
      # react to a change in metadata selection (e.g. the home route), so just ignore it.
