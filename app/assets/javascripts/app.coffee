#= require ./core
#= require_tree ./data/
#= require_tree ./models
#= require_tree ./controllers
#= require_tree ./views
#= require_tree ./helpers
#= require_tree ./templates
#= require_tree ./states

App.reopen
  ready: ->
    @loadData()
    @connectControllers()


  loadData: ->
    corpusId = 1  # TESTING!!!
    corpus = App.Corpus.find(corpusId)
    App.set('router.selectedCorpusController.content', corpus)

    App.MetadataValue.find({ corpus_id: corpusId })


  connectControllers: ->
    App.get('router.metadataAccordionController').connectControllers('selectedCorpus')
