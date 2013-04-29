App.CwbResultTableController = Em.Controller.extend

  needs: ['resultTable']

  # We get the actual page of results from the resultTableController; this
  # controller is only responsible for doing CWB-specific formatting of
  # those results
  resultPageBinding: 'controllers.resultTable.content'

  tooltips: {}

  arrangedContent: (->
    resultPage = @get('resultPage')

    if resultPage
      resultPage.map (row) ->
        m = row.match(/<s_id (.+)>:\s+(.*)<(.+?)>(.*)/)
        sId = m[1]
        fields = [m[2], m[3], m[4]]

        fields = fields.map (field) ->
          tokens = field.split(/\s+/).map (token) ->
            parts = token.split('/')
            "<span data-ot=\"lemma: #{parts[1]}\">#{parts[0]}</span>"
          tokens.join(' ')

        sId:       sId
        preMatch:  fields[0]
        match:     fields[1]
        postMatch: fields[2]
    else
      []
  ).property('resultPage.@each')
