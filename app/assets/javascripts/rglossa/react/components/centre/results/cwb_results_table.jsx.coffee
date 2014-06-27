###* @jsx React.DOM ###

window.CwbResultsTable = React.createClass
  propTypes:
    resultPage: React.PropTypes.array.isRequired
    corpus: React.PropTypes.object.isRequired
    rowNoShowingPlayer: React.PropTypes.number


  parseResults: (resultPage) ->
    labels = @props.corpus.langs[0].displayAttrs or corpus.displayAttrs or []
    resultPage.map (result) ->
      m = result.text.match(/<\w+_id(.*)>:\s+(.*){{(.+?)}}(.*)/)
      if m
        sId = m[1].trim()
        fields = [m[2], m[3], m[4]]
      else
        # No structural attribute surrounding the hit, so just find the colon following the
        # position number and grab everything following it
        m = result.text.match(/:\s+(.*){{(.+?)}}(.*)/)
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
      mediaObj:  result.media_obj


  mainRow: (result) ->
    corpusHasSound = @props.corpus.has_sound
    `<tr>
      {result.sId ? <td>{result.sId}</td> : null}
      {corpusHasSound
        ? <td className="span1">
            <button className="btn" AAaction="" togglejplayerBB=""><i className="icon-volume-up" /></button>
          </td>
        : null}
      <td dangerouslySetInnerHTML={{__html: result.preMatch}} />
      <td dangerouslySetInnerHTML={{__html: result.match}} />
      <td dangerouslySetInnerHTML={{__html: result.postMatch}} />
    </tr>`


  extraRow: (attr) ->
    return `<tr><td colSpan={3}>hei</td></tr>`
    corpusHasSound = @props.corpus.has_sound
    match = (value for key, value of @get('mediaObj.divs.annotation') when value.is_match)[0]
    rowContents = (value.orig for key, value of match.line).join(' ')
    `<tr>
      {result.sId ? <td /> : null}
      {corpusHasSound ? <td className="span1" /> : null}
      <td colSpan="3">{rowContents}</td>
    </tr>`


  loadingIndicator: ->
    `<div className="spinner-searching-large"></div>`


  resultTable: ->
    results = @parseResults(@props.resultPage)
    extraRowAttrs = @props.corpus.extra_row_attrs or []

    `<div className="row-fluid search-result-table-container">
      <table className="table table-striped table-bordered">
        <tbody>
        {results.map(function(result, index) {
          var mainRow = this.mainRow(result),
              extraRows = extraRowAttrs.map(this.extraRow);
              rows = [mainRow, extraRows];
          if(this.props.rowNoShowingPlayer === index) {
            rows.push(
              <tr>
                <td colSpan="10">
                  AAj-player mediaObj=result.mediaObjBB
                </td>
              </tr>
            );
          }
          return rows;
        }, this)}
      </tbody>
      </table>
    </div>`


  render: ->
    if @props.resultPage then @resultTable() else @loadingIndicator()
