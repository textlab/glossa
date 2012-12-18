App.CwbResultsController = Em.Controller.extend
  resultsBinding: 'resultToolbarController.content'

  arrangedContent: (->
    @get('results').map (row) ->
      m = row.match(/<s_id (.+)>:\s+(.+)<(.+?)>(.+)/)
      sId:       m[1]
      preMatch:  m[2]
      match:     m[3]
      postMatch: m[4]
  ).property('results')
