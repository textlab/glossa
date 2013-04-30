App.SearchController = Em.ObjectController.extend
  needs: ['searches']

  content: null
  contentBinding: 'controllers.searches.currentSearch'