App.SearchCwbRoute = Em.Route.extend

  setupController: ->
    # Regardless of the specific search inteface used (simple, regex etc.),
    # which will be set by a substate, we now know that are using the CWB, so
    # the cwbResultPageController should be used to format search results
    @controllerFor('resultPage')
      .set('formattingController', @controllerFor('cwbResultPage'))
