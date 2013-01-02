App.CwbResultPageController = Em.Controller.extend
  # We get the actual page of results from the resultPageController; this
  # controller is only responsible for doing CWB-specific formatting of
  # those results
  resultPageBinding: 'resultPageController.content'

  arrangedContent: (->
    @get('resultPage').map (row) ->
      m = row.match(/<s_id (.+)>:\s+(.+)<(.+?)>(.+)/)
      sId:       m[1]
      preMatch:  m[2]
      match:     m[3]
      postMatch: m[4]
  ).property('resultPage')
