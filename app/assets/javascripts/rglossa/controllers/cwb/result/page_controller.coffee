App.CwbResultPageController = Em.Controller.extend

  needs: ['resultPage']

  # We get the actual page of results from the resultPageController; this
  # controller is only responsible for doing CWB-specific formatting of
  # those results
  resultPageBinding: 'controllers.resultPage.content'

  arrangedContent: (->
    resultPage = @get('resultPage')

    if resultPage
      resultPage.map (row) ->
        m = row.match(/<s_id (.+)>:\s+(.+)<(.+?)>(.+)/)
        sId:       m[1]
        preMatch:  m[2]
        match:     m[3]
        postMatch: m[4]
    else
      []
  ).property('resultPage')
