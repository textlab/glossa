#= require rglossa/models/corpus

###* @jsx React.DOM ###

window.CwbResultsTable = React.createClass
  propTypes:
    resultPage: React.PropTypes.array
    corpus: React.PropTypes.object.isRequired

  getInitialState: ->
    rowNoShowingPlayer: null
    playerType: null
    mediaTypePlaying: null

  componentWillReceiveProps: ->
    # Make sure jPlayer is closed when we receive a new page of results
    @setState(rowNoShowingPlayer: null, playerType: null, mediaTypePlaying: null)

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
        m = result.text.match(/<(\w+_(?:id|name))(.*?)>(.*){{(.+?)}}(.*?)<\/\1>$/)
        if m
          sId = m[2].trim()
          fields = [m[3], m[4], m[5]]
        else
          # Try again without the surrounding structural attribute
          m = result.text.match(/(.*){{(.+?)}}(.*)/)
          sId = ''
          fields = [m[1], m[2], m[3]]
      else
        # No {{ was found, so this is a result from a non-first language in a multilingual search.
        # Extract the IDs of all s-units (typically sentences) and put them in front of their
        # respective s-units.
        text = result.text.replace(/<(\w+_id)\s*(.+?)>(.*?)<\/\1>/g,
          '<span class="aligned-id">$2</span>: $3')
        fields = [text]

      fields = fields.map (field) ->
        # Extract any speaker IDs and put them in front of their segments
        field = field.replace(/<who_name\s*(.+?)>/g,
          '<span class="speaker-id">&lt;$1&gt;</span> ')
        field = field.replace(/<\/who_name>/g, '')

        tokens = field.replace(/span class=/g, 'span_class=').split(/\s+/).map (token) ->
          return token if token.indexOf('span_class=') isnt -1 # don't touch HTML spans

          parts = token.split('/')  # the slash separates CWB attributes

          maxIndex = labels.length
          ot = []
          if maxIndex
            # If there are any CWB attributes to show for each token, create data-ot HTML
            # attributes that will be used by the Opentip jQuery plugin to display them in a tooltip
            for i in [1..maxIndex]
              if parts[i] != '__UNDEF__' and parts[i] != '_'
                ot.push "#{labels[i-1]}: #{parts[i]}"

          outToken = if ot.length
            "<span data-ot=\"#{ot.join('<br>')}\">#{parts[0]}</span>"
          else
            # No CWB attributes, so no data-ot attribute needed
            "<span>#{parts[0]}</span>"
          chineseCharsRange = '[\u4E00-\u9FFF\u3400-\u4DFF\uF900-\uFAFF]'
          if parts[0].match(///^#{chineseCharsRange}+$///)
            outToken
          else
            " #{outToken} "

        tokens.join('').replace(/span_class=/g, 'span class=')

      sId:       sId
      preMatch:  fields[0]
      match:     fields[1]
      postMatch: fields[2]
      mediaObj:  result.media_obj


  togglePlayer: (index, playerType, mediaType) ->
    rowNo = if (@state.rowNoShowingPlayer is index and playerType is @state.playerType and
                mediaType is @state.mediaTypePlaying) then null else index
    mediaTypePlaying = if rowNo? then mediaType else null
    @setState(rowNoShowingPlayer: rowNo, playerType: playerType, mediaTypePlaying: mediaTypePlaying)


  mainRow: (result, index) ->
    corpusHasVideo = @props.corpus.has_video
    corpusHasSound = @props.corpus.has_sound
    `<tr>
      {corpusHasVideo || corpusHasSound
        ? <td className="span1">
            {corpusHasVideo && <button title="Show video" className="btn btn-mini" style={{width: '100%'}} onClick={this.togglePlayer.bind(null, index, 'jplayer', 'video')} style={{marginBottom: 3}}><i className="icon-film" /></button>}
            {corpusHasSound && <button title="Play audio" className="btn btn-mini" style={{width: '100%'}}  onClick={this.togglePlayer.bind(null, index, 'jplayer', 'audio')}><i className="icon-volume-up" /></button>}
            {corpusHasSound && <button title="Show waveform" className="btn btn-mini" style={{width: '100%'}}  onClick={this.togglePlayer.bind(null, index, 'wfplayer', 'audio')}><img src="assets/rglossa/speech/waveform.png" /></button>}
          </td>
        : null}
      {this.idColumn(result)}
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
            dangerouslySetInnerHTML={{__html: result.preMatch}} />]`


  extraRow: (result, attr) ->
    corpusHasVideo = @props.corpus.has_video
    corpusHasSound = @props.corpus.has_sound
    match = (value for key, value of result.mediaObj.divs.annotation when value.is_match)[0]
    rowContents = (value[attr] for key, value of match.line).join(' ')
    `<tr>
      {result.sId ? <td /> : null}
      {corpusHasVideo || corpusHasSound ? <td className="span1" /> : null}
      <td colSpan="3">{rowContents}</td>
    </tr>`


  loadingIndicator: ->
    `<div className="spinner-searching-large"></div>`


  ResultTable: ->
    results = @parseResults(@props.resultPage)
    extraRowAttrs = @props.corpus.extra_row_attrs or []

    `<div className="row-fluid search-result-table-container">
      <table className="table table-striped table-bordered">
        <tbody>
        {results.map(function(result, index) {
          var mainRow = this.mainRow(result, index),
              extraRows = extraRowAttrs.map(this.extraRow.bind(null, result));
              rows = [mainRow, extraRows];
          if(this.state.rowNoShowingPlayer === index) {
            if(this.state.playerType === "jplayer") {
              rows.push(
                <tr>
                  <td colSpan="10">
                    <Jplayer mediaObj={result.mediaObj} mediaType={this.state.mediaTypePlaying}
                             ctx_lines={this.props.corpus.initial_context_size || 1} />
                  </td>
                </tr>
              );
            } else if(this.state.playerType === "wfplayer") {
              rows.push(
                <tr>
                  <td colSpan="10">
                    <WFplayer mediaObj={result.mediaObj} />
                  </td>
                </tr>
              );
            }
          }
          return rows;
        }, this)}
      </tbody>
      </table>
    </div>`


  render: ->
    if @props.resultPage then @ResultTable() else @loadingIndicator()
