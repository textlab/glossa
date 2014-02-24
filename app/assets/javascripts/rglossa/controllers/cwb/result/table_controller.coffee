App.CwbResultTableController = Em.Controller.extend

  needs: ['resultTable', 'corpus']

  # We get the actual page of results from the resultTableController; this
  # controller is only responsible for doing CWB-specific formatting of
  # those results
  resultPageBinding: 'controllers.resultTable.content'
  corpusBinding: 'controllers.corpus.content'

  tooltips: {}

  arrangedContent: (->
    resultPage = @get('resultPage')
    displayAttrs = @get('corpus.langs.firstObject.displayAttrs')

    if resultPage
      resultPage.map (row) ->
        m = row.match(/<s_id(.*)>:\s+(.*)<(.+?)>(.*)/)
        sId = m[1].trim()
        fields = [m[2], m[3], m[4]]

        fields = fields.map (field) ->
          tokens = field.split(/\s+/).map (token) ->
            parts = token.split('/')

            labels = displayAttrs
            maxIndex = labels.length
            ot = []
            for i in [1..maxIndex]
              if parts[i] != '__UNDEF__'
                ot.push "#{labels[i-1]}: #{parts[i]}"
            "<span data-ot=\"#{ot.join('<br>')}\">#{parts[0]}</span>"
          tokens.join(' ')

        sId:       sId
        preMatch:  fields[0]
        match:     fields[1]
        postMatch: fields[2]
    else
      []
  ).property('resultPage.@each')
