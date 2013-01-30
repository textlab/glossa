App.SearchController = Em.ObjectController.extend
  needs: ['searches']

  model: null
  modelBinding: 'controllers.searches.currentSearch'