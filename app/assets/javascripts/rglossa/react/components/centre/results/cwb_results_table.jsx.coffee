#= require rglossa/react/models/corpus

###* @jsx React.DOM ###

window.CwbResultsTable = React.createClass
  propTypes:
    resultPage: React.PropTypes.array
    corpus: React.PropTypes.object.isRequired
    rowNoShowingPlayer: React.PropTypes.number

  componentDidUpdate: (prevProps) ->
    # Create tooltips after a new result page is displayed
    if @props.resultPage and @props.resultPage[0] isnt prevProps.resultPage?[0]
      $('[data-ot]', @getDOMNode()).each (index, token) ->
        new Opentip token, $(token).data('ot'),
          style: 'dark'
          fixed: true
          removeElementsOnHide: true

  parseResults: (resultPage) ->
    labels = corpusNs.getLabels(@props.corpus)
    resultPage.map (result) ->
      if result.text.indexOf('{{') isnt -1
        # The result contains {{, which is the left delimiter of a match, meaning that
        # this is a result from a monolingual search or from the first language of a
        # multilingual search.

        # There will only be a surrounding structural attribute if the corpus has some
        # kind of s-unit segmentation
        m = result.text.match(/<(\w+_id)(.*?)>(.*){{(.+?)}}(.*)<\/\1>$/)
        if m
          sId = m[2].trim()
          fields = [m[3], m[4], m[5]]
        else
          # Try again without the surrounding structural attribute
          m = result.text.match(/(.*){{(.+?)}}(.*)/)
          sId = ''
          fields = [m[1], m[2], m[3]]
      else
        # No {{ was found, so this is a result from a non-first language in a multilingual search
        m = result.text.match(/<(\w+_id)(.*?)>(.*)<\/\1>$/)
        if m
          sId = m[2].trim()
          fields = [m[3]]
        else
          # Without a surrounding structural attribute we just use the entire text
          fields = [result.text]

      fields = fields.map (field) ->
        tokens = field.split(/\s+/).map (token) ->
          parts = token.split('/')  # the slash separates CWB attributes

          maxIndex = labels.length
          ot = []
          if maxIndex
            # If there are any CWB attributes to show for each token, create data-ot HTML
            # attributes that will be used by the Opentip jQuery plugin to display them in a tooltip
            for i in [1..maxIndex]
              if parts[i] != '__UNDEF__'
                ot.push "#{labels[i-1]}: #{parts[i]}"
            "<span data-ot=\"#{ot.join('<br>')}\">#{parts[0]}</span>"
          else
            # No CWB attributes, so no data-ot attribute needed
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
      {this.idColumn(result)}
      {corpusHasSound
        ? <td className="span1">
            <button className="btn" AAaction="" togglejplayerBB=""><i className="icon-volume-up" /></button>
          </td>
        : null}
      {this.textColumns(result)}
    </tr>`


  idColumn: (result) ->
    # If the 'match' property is defined, we know that we have a result from a monolingual
    # search or the first language of a multilingual one. If that is the case, and sId is
    # defined, we print it in the first column (if we have a non-first language result, we
    # will include it in the next column instead).
    if result.match and result.sId then `<td>{result.sId}</td>` else null


  textColumns: (result) ->
    if result.match
      # If the 'match' property is defined, we know that we have a result from a monolingual
      # search or the first language of a multilingual one, and then we want preMatch, match
      # and postMatch in separate columns.
      `[<td dangerouslySetInnerHTML={{__html: result.preMatch}} />,
        <td className="match" dangerouslySetInnerHTML={{__html: result.match}} />,
        <td dangerouslySetInnerHTML={{__html: result.postMatch}} />]`
    else
      # Otherwise, we have a result from a non-first language of a multilingual search. In that
      # case, CQP doesn't mark the match, so we leave the first column blank and put all of the
      # text in a single following column.
      `[<td />,
        <td className="aligned-text" colSpan="3"
            dangerouslySetInnerHTML={{__html: result.sId + ': ' + result.preMatch}} />]`


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
