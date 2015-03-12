###* @jsx React.DOM ###

window.TextBox = React.createClass
  propTypes:
    mediaObj: React.PropTypes.object.isRequired
    startAtLine: React.PropTypes.number.isRequired
    endAtLine: React.PropTypes.number.isRequired

  getInitialState: ->
    wfPlayer: null

  renderWord: (line) ->
    att_string = ""
    for att of line
      if att is "pos"
        # pos tags contain multiple values seperated by colons
        line[att] = line[att].replace(/:/g,"/")
      att_string += att + " : " + line[att] + "<br>"
    `<a title={att_string} style={line.match ? {color: '#b00', fontWeight: 'bold', fontSize: '0.9em'} : {}}>{line[this.props.mediaObj.display_attribute]} </a>`

  renderAnnotation: (annotation, lineNo) ->
      timecode = annotation.from
      end_timecode = annotation.to
      speaker = annotation.speaker
      speaker_brev = speaker.replace(/^.*_/,"")
      segment = (@renderWord(annotation.line[i]) for i of annotation.line)
      getStyle = () =>
        if parseInt(lineNo) == parseInt(@props.highlightLine)
          { display: 'table-row', color: '#000', 'background-color': '#eea' }
        else if lineNo >= @props.startAtLine and lineNo <= @props.endAtLine
          { display: 'table-row', color: '#000' }
        else if annotation.from is @first_start or annotation.to is @last_end
          # ie, overlapping segments
          { display: 'table-row', color: '#ccc' }
        else
          { display: 'none' }

      textDivs = []
      textDivs.push `<div className={'textDiv ' + timecode.replace(/\./,"_")}
            id={'jp-' + lineNo}
            data-start_timecode={timecode}
            data-end_timecode={end_timecode}
            style={getStyle()}
            >
         <div className="waveformBtnDiv"><button title="Show waveform" className="btn btn-mini" style={{width: '100%'}} onClick={this.toggleWFplayer.bind(this, lineNo)}><img src="assets/rglossa/speech/waveform.png" /></button></div>
         <div className="speakerDiv"><a className="speaker" title={speaker}>{speaker_brev}</a></div>
         <div className="segmentDiv">{segment}</div>
       </div>
       `
      if @state.wfPlayer == lineNo
        textDivs.push `<div className="waveDiv"><WFplayer mediaObj={this.props.mediaObj} startAt={lineNo} endAt={lineNo} /></div>`
      textDivs

  toggleWFplayer: (line) ->
    if @state.wfPlayer != line
      @setState(wfPlayer: line)
      @props.pauseJPlayer()
    else
      @setState(wfPlayer: null)

  render: ->
    display_attribute = @props.mediaObj.display_attribute
    annotation = @props.mediaObj.divs.annotation
    @first_start = annotation[@props.startAtLine].from
    @last_end = annotation[@props.endAtLine].to

    annotations = (@renderAnnotation(annotation[n], n) for n of annotation)

    `<div className="jplayer-text autocue">{annotations}</div>`


window.Jplayer = React.createClass
  propTypes:
    mediaObj: React.PropTypes.object.isRequired
    mediaType: React.PropTypes.string.isRequired

  getStartLine: (mediaObj) ->
    start_at = parseInt(mediaObj.start_at)
    min_start = parseInt(mediaObj.min_start)
    if !@props.ctx_lines
      start_at
    else if @props.ctx_lines == 'all'
      min_start
    else if start_at - @props.ctx_lines >= min_start
      start_at - @props.ctx_lines
    else
      min_start

  getEndLine: (mediaObj) ->
    end_at = parseInt(mediaObj.end_at)
    max_end = parseInt(mediaObj.max_end)
    if !@props.ctx_lines
      end_at
    else if @props.ctx_lines == 'all'
      max_end
    else if end_at + @props.ctx_lines <= max_end
      end_at + @props.ctx_lines
    else
      max_end

  getStartTime: (mediaObj) ->
    parseFloat mediaObj.divs.annotation[@state.startLine].from

  getEndTime: (mediaObj) ->
    parseFloat mediaObj.divs.annotation[@state.endLine].to

  getInitialState: ->
    startLine: @getStartLine(@props.mediaObj)
    endLine: @getEndLine(@props.mediaObj)
    currentLine: @getStartLine(@props.mediaObj)
    restart: false

  componentDidMount: ->
    @createPlayer()

  componentDidUpdate: ->
    @restartPlayer() if @state.restart

  componentWillUnmount: ->
    @destroyPlayer()

  pauseJPlayer: ->
    $node = $(@getDOMNode())
    $playerNode = $node.find(".jp-jplayer")
    $playerNode.jPlayer( "pause" )

  createPlayer: ->
    $node = $(@getDOMNode())
    mediaObj = @props.mediaObj

    $(document).tooltip
      content: -> $node.prop('title')

    mov = mediaObj.mov.movie_loc
    path = "#{mediaObj.mov.path}/#{@props.mediaType}/"
    supplied = mediaObj.mov.supplied
    $("#movietitle").text(mediaObj.title)
    last_line = parseInt(mediaObj.last_line)

    ext = if @props.mediaType == "audio" then ".mp3" else "_800.mp4"
    $playerNode = $node.find(".jp-jplayer")
    $playerNode.jPlayer
      solution: "flash, html"
      ready: =>
        $playerNode.jPlayer "setMedia",
          rtmpv: path+mov+ext
          m4v: path+mov+ext
          poster: "assets/rglossa/speech/_6.6-%27T%27_ligo.skev.graa.jpg"
        $playerNode.jPlayer( "play", @getStartTime(mediaObj))

      timeupdate: (event) =>
        ct = event.jPlayer.status.currentTime
        if ct > @getEndTime(mediaObj)
          $playerNode = $node.find(".jp-jplayer")
          $playerNode.jPlayer("play", @getStartTime(mediaObj))
          $playerNode.jPlayer( "pause" )
          @setState(currentLine: @getStartLine(mediaObj), restart: false)
        else if ct > mediaObj.divs.annotation[@state.currentLine].to
          @setState(currentLine: @state.currentLine+1, restart: false)

#      ended: -> alert("ended!")

      swfPath: ""
      supplied: supplied
      solution: 'html, flash'
      preload: 'metadata'


    # Slider widget
    $( ".slider-range" ).slider
        range: true
        min: 0
        max: last_line
        values: [ @state.startLine, @state.endLine+1 ]

        slide: ( event, ui ) =>
          return false if ui.values[1] - ui.values[0] < 1
          $playerNode.jPlayer( "stop" )
          @setState(restart: true, currentLine: ui.values[0], startLine: ui.values[0], endLine: ui.values[1]-1) #eg,  2 - 3 means play 1 segment


  destroyPlayer: ->
    $node = $(@getDOMNode())
    $node.find(".jp-jplayer").jPlayer('destroy')

  restartPlayer: ->
    $node = $(@getDOMNode())
    $playerNode = $node.find(".jp-jplayer")
    $playerNode.jPlayer("play", @getStartTime(@props.mediaObj))

  render: ->
    `<div style={{position: 'relative'}}>
      <div style={{float: 'right', width: 480}}>
      <div className="jp-video jp-video-270p" id="jp_container_1">
         <div className="jp-type-single">
             <div className="jp-jplayer" style={this.props.mediaType == 'audio' ? {display: 'none'} : {width: 480, height: 270}}>
                 <img id="jp_poster_1" src="http://www.hf.uio.no/iln/om/organisasjon/tekstlab/BILDER/_6.6-%27T%27_ligo.skev.graa.jpg" style={{width: 480, height: 270, display: 'none'}} />
                 <object id="jp_flash_1" name="jp_flash_1" data="Jplayer.swf" type="application/x-shockwave-flash" width="1" height="1" tabIndex="-1" style={{width: 1, height: 1}}>
                     <param name="flashvars" value="jQuery=jQuery&amp;id=jplayer&amp;vol=0.8&amp;muted=false" />
                     <param name="allowscriptaccess" value="always" />
                     <param name="bgcolor" value="#000000" />
                     <param name="wmode" value="opaque" />
                 </object>
             </div>
             <div className="jp-gui">
                 <div className="jp-video-play" style={this.props.mediaType == 'audio' ? {display: 'none', visibility: 'hidden'} : {display: 'none'}}>
                     <a href="javascript:;" className="jp-video-play-icon" tabIndex="1">play</a>
                 </div>
                 <div className="jp-interface">
                     <div>&nbsp;</div>
                     <div className="jp-controls-holder">
                         <ul className="jp-controls">
                             <li><a href="javascript:;" className="jp-play" tabIndex="1" title="play" style={{display: 'block'}}>play</a></li>
                             <li><a href="javascript:;" className="jp-pause" tabIndex="1" title="pause" style={{display: 'none'}}>pause</a></li>
                             <li><a href="javascript:;" className="jp-mute" tabIndex="1" title="mute">mute</a></li>
                             <li><a href="javascript:;" className="jp-unmute" tabIndex="1" title="unmute" style={{display: 'none'}}>unmute</a></li>
                             <li><a href="javascript:;" className="jp-volume-max" tabIndex="1" title="volume max">volume-max</a></li>
                         </ul>
                         <div className="jp-volume-bar">
                             <div className="jp-volume-bar-value" style={{width: '80%'}}></div>
                         </div>
                     </div>
                     <div className="jp-title"><ul><li id="movietitle">kristiansand_01um-02uk</li></ul></div>
                 </div>
             </div>
             <div className="jp-no-solution" style={{display: 'none'}}>
                 <span>Update required</span><a href="http://get.adobe.com/flashplayer/" target="_blank">Flash plugin</a>
             </div>
         </div>
      </div>
      <div className="slider-range ui-slider ui-slider-horizontal ui-widget ui-widget-content ui-corner-all" aria-disabled="false">
          <div className="ui-slider-range ui-widget-header ui-corner-all" style={{left: '40%', width: '40%'}}></div>
          <a className="ui-slider-handle ui-state-default ui-corner-all" href="#" style={{left: '40%'}}></a>
          <a className="ui-slider-handle ui-state-default ui-corner-all" href="#" style={{left: '80%'}}></a>
      </div>
      </div>
      <TextBox mediaObj={this.props.mediaObj} startAtLine={this.state.startLine} endAtLine={this.state.endLine} highlightLine={this.state.currentLine} pauseJPlayer={this.pauseJPlayer} />
    </div>`
