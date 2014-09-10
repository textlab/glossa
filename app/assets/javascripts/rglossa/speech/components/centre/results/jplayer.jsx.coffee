###* @jsx React.DOM ###

window.Jplayer = React.createClass
  propTypes:
    mediaObj: React.PropTypes.object.isRequired
    mediaType: React.PropTypes.string.isRequired

  componentDidMount: ->
    @createPlayer()

  componentDidUpdate: ->
    @destroyPlayer()
    @createPlayer()

  componentWillUnmount: ->
    @destroyPlayer()

  createPlayer: ->
    $node = $(@getDOMNode())
    mediaObj = @props.mediaObj
    @textBox = @createTextBox()

    $(document).tooltip
      content: -> $node.prop('title')

    mov = mediaObj.mov.movie_loc
    path = "#{mediaObj.mov.path}/#{@props.mediaType}/"
    supplied = mediaObj.mov.supplied
    $("#movietitle").text(mediaObj.title)
    last_line = parseInt(mediaObj.last_line)

    @textBox.init($node, mediaObj)

    @textBox.currentID = parseInt(mediaObj.start_at)

    start = parseInt(mediaObj.start_at)
    stop  = parseInt(mediaObj.end_at)
    @textBox.redraw(start,stop, last_line)
    start = parseFloat($("#jp-"+start).data("start_timecode"))
    stop  = parseFloat($("#jp-"+stop).data("end_timecode"))

    console.log(mediaObj)

    $playerNode = $node.find(".jp-jplayer")
    $playerNode.jPlayer
      solution: "flash, html"
      ready: ->
        $playerNode.jPlayer "setMedia",
          rtmpv: path + mov
          m4v: path+mov
          poster: "assets/rglossa/speech/_6.6-%27T%27_ligo.skev.graa.jpg"
        $playerNode.jPlayer( "play", start)

      timeupdate: (event) =>
        ct = event.jPlayer.status.currentTime
        if ct > stop
          $playerNode = $node.find(".jp-jplayer")
          $playerNode.jPlayer("play", start)
          $playerNode.jPlayer( "pause" )
        else if ct > @textBox.currentEndTime
          @textBox.update(ct)

      ended: -> alert("ended!")

      swfPath: ""
      supplied: supplied
      solution: 'html, flash'
      preload: 'metadata'


    # Slider widget
    $( ".slider-range" ).slider
        range: true
        min: 0
        max: last_line
        values: [ @textBox.start_at_line, @textBox.end_at_line+1 ]

        slide: ( event, ui ) =>
          return false if ui.values[1] - ui.values[0] < 1

          first = ui.values[ 0 ]
          last = ui.values[ 1 ] - 1  #eg,  2 - 3 means play 1 segment
          @textBox.redraw(first,last, last_line)

          start = parseFloat($("#jp-"+first).data("start_timecode"))
          stop = parseFloat($("#jp-"+last).data("end_timecode"))

          $node.find(".js-jplayer").jPlayer("play", start)


  destroyPlayer: ->
    $(@getDOMNode()).find(".jp-jplayer").jPlayer('destroy')


  createTextBox: =>
    start_at_line:0
    end_at_line:0
    currentID:0
    nextID:0
    currentEndTime:0
    currentStartTime:0

    init: ($view, mediaObj) ->
      display_attribute = mediaObj.display_attribute
      annotation = mediaObj.divs.annotation
      @start_at_line = parseInt(mediaObj.start_at)
      @end_at_line = parseInt(mediaObj.end_at)
      @currentID = @start_at_line
      @nextID = @start_at_line + 1

      for n of annotation
        timecode = annotation[n].from
        end_timecode = annotation[n].to
        speaker = annotation[n].speaker
        speaker_brev = speaker.replace(/^.*_/,"")

        div = $('<div>')
        .addClass("textDiv")
        .addClass(timecode.replace(/\./,"_"))
        .attr("id", 'jp-' + n)
        .data("start_timecode",timecode)
        .data("end_timecode",end_timecode)
        .on "click", (e) -> alert($view.data("start_timecode")+" id:"+$view.attr("id"))

        if n < @start_at_line or n > @end_at_line
          div.css({"display":"none"})

        speakerDiv = $('<div>')
        .addClass('speakerDiv')

        anchor = $('<a>')
        .addClass('speaker')
        .text(speaker_brev)
        .attr("title",speaker)

        speakerDiv.append(anchor)

        segmentDiv = $("<div>")
        .addClass('segmentDiv')

        line = annotation[n].line

        for i of line
          match = false;
          att_string = ""

          match = true if line[i].match

          for att of line[i]
            if att is "pos"
              # pos tags contain multiple values seperated by colons
              line[i][att] = line[i][att].replace(/:/g,"/")
            att_string += att + " : " + line[i][att] + "<br>"

          anchor = $('<a>')
          .attr("title",att_string)
          .text(line[i][display_attribute])

          segmentDiv.append(anchor)
          segmentDiv.append(" ")

          if match
            anchor
            .css({"color":"#b00"})
            .css({"font-weight":"bold"})
            .css({"font-size":"0.9em"})

        div.append(speakerDiv)
        div.append(segmentDiv)
        $view.find('.jplayer-text').append(div)


    redraw: (first, last, last_line) ->
      @currentID = first
      @currentEndTime = 0
      first_start = $("#jp-"+first).data("start_timecode")
      last_end = $("#jp-"+last).data("end_timecode")

      for i in [0..last_line]
        $("#jp-"+i).css("background-color","#fff")
        if i >= first and i <= last
          $("#jp-"+i).css({"display":"table-row","color":"#000"})
          continue

        if ($("#jp-"+i).data("start_timecode") is first_start) or ($("#jp-"+i).data("end_timecode") is last_end)
          # ie, overlapping segments
          $("#jp-"+i).css({"display":"table-row","color":"#ccc"})
          continue

      $("#jp-"+i).css({"display":"none"})


    update: (ct) ->
      iterate = true

      while iterate
        currentEndTime = $("#jp-"+@currentID).data("end_timecode")
        currentStartTime = $("#jp-"+@currentID).data("start_timecode")
        if currentEndTime > ct
          @currentEndTime = currentEndTime
          $("."+currentStartTime.replace(/\./,"_")).css("background-color","#eea")
          @currentEndTime = currentEndTime
          iterate = false
        else
          $("."+currentStartTime.replace(/\./,"_")).css("background-color","#fff")
          @currentID++

      @nextID++
      @currentEndTime


  render: ->
    `<div style={{position: 'relative'}}>
      <div className="jp-video jp-video-270p" id="jp_container_1">
         <div className="jp-type-single">
             <div className="jp-jplayer" style={{width: 480, height: 270}}>
                 <img id="jp_poster_1" src="http://www.hf.uio.no/iln/om/organisasjon/tekstlab/BILDER/_6.6-%27T%27_ligo.skev.graa.jpg" style={{width: 480, height: 270, display: 'none'}} />
                 <object id="jp_flash_1" name="jp_flash_1" data="Jplayer.swf" type="application/x-shockwave-flash" width="1" height="1" tabIndex="-1" style={{width: 1, height: 1}}>
                     <param name="flashvars" value="jQuery=jQuery&amp;id=jplayer&amp;vol=0.8&amp;muted=false" />
                     <param name="allowscriptaccess" value="always" />
                     <param name="bgcolor" value="#000000" />
                     <param name="wmode" value="opaque" />
                 </object>
             </div>
             <div className="jp-gui">
                 <div className="jp-video-play" style={{display: 'none'}}>
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
      <div className="jplayer-text autocue"></div>
      <div className="slider-range ui-slider ui-slider-horizontal ui-widget ui-widget-content ui-corner-all" aria-disabled="false">
          <div className="ui-slider-range ui-widget-header ui-corner-all" style={{left: '40%', width: '40%'}}></div>
          <a className="ui-slider-handle ui-state-default ui-corner-all" href="#" style={{left: '40%'}}></a>
          <a className="ui-slider-handle ui-state-default ui-corner-all" href="#" style={{left: '80%'}}></a>
      </div>
    </div>`
