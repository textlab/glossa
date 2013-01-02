App.CwbRoute = Em.Route.extend

  enter: ->
    # Regardless of the specific search inteface used (simple, regex etc.),
    # which will be set by a substate, we now know that are using the CWB, so
    # the cwbResultPageController should be used to format search results
    Em.controllerFor('resultPage')
      .set('formattingController', Em.controllerFor('cwbResultPage'))
