App.CwbResultsController = Em.ArrayController.extend
  content: []

  arrangedContent: (->
    @get('content').map (row) ->
      m = row.match(/<s_id (.+)>:\s+(.+)<(.+?)>(.+)/)
      sId:       m[1]
      preMatch:  m[2]
      match:     m[3]
      postMatch: m[4]
  ).property('content')

  hasMoreThanOnePage: (->
    true
  ).property('content')