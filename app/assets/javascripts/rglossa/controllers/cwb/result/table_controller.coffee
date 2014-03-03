App.CwbResultTableController = Em.Controller.extend

  needs: ['resultTable', 'corpus']

  # We get the actual page of results from the resultTableController; this
  # controller is only responsible for doing CWB-specific formatting of
  # those results
  resultPageBinding: 'controllers.resultTable.content'
  corpusBinding: 'controllers.corpus.content'

  corpusHasSound: (-> @get('corpus.hasSound')).property('corpus')

  tooltips: {}

  arrangedContent: (->
    resultPage = @get('resultPage')
    labels = @get('corpus.langs.firstObject.displayAttrs') || []

    if resultPage
      resultPage.map (row) ->
        m = row.match(/<\w+_id(.*)>:\s+(.*)<(.+?)>(.*)/)
        if m
          sId = m[1].trim()
          fields = [m[2], m[3], m[4]]
        else
          # No structural attribute surrounding the hit, so just find the colon following the
          # position number and grab everything following it
          m = row.match(/:\s+(.*)<(.+?)>(.*)/)
          sId = ''
          fields = [m[1], m[2], m[3]]

        fields = fields.map (field) ->
          tokens = field.split(/\s+/).map (token) ->
            parts = token.split('/')

            maxIndex = labels.length
            ot = []
            if maxIndex
              for i in [1..maxIndex]
                if parts[i] != '__UNDEF__'
                  ot.push "#{labels[i-1]}: #{parts[i]}"
              "<span data-ot=\"#{ot.join('<br>')}\">#{parts[0]}</span>"
            else
              "<span>#{parts[0]}</span>"

          tokens.join(' ')

        sId:       sId
        preMatch:  fields[0]
        match:     fields[1]
        postMatch: fields[2]
    else
      []
  ).property('resultPage.@each')
