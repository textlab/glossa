App.CorpusHomeController = Em.Controller.extend

  needs: ['corpus', 'searches']

  corpusBinding: 'controllers.corpus.model'
  searchesControllerBinding: 'controllers.searches'
