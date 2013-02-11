App.CwbResultTableController = Em.Controller.extend

  needs: ['resultTable']

  # We get the actual page of results from the resultTableController; this
  # controller is only responsible for doing CWB-specific formatting of
  # those results
  resultPageBinding: 'controllers.resultTable.content'

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
  ).property('resultPage.@each')
