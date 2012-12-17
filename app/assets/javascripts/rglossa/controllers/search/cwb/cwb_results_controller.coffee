App.CwbResultsController = Em.ArrayController.extend
  content: []

  arrangedContent: (->
    @get('content').map (row) ->
      m = row.match(/^\s*\d+:\s+(.+)<(.+?)>(.+)/)
      preMatch:  m[1]
      match:     m[2]
      postMatch: m[3]
  ).property('content')