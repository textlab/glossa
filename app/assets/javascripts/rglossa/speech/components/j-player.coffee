App.JPlayerComponent = Em.Component.extend
  classNames: 'jplayer-container'

  didInsertElement: ->
    @textBox = @createTextBox()

    $(document).tooltip
      content: -> $(@).prop('title')

    mov = @mediaObj.mov.movie_loc
    path = @mediaObj.mov.path
    supplied = @mediaObj.mov.supplied
    $("#movietitle").text(@mediaObj.title)
    last_line = parseInt(@mediaObj.last_line)

    @textBox.init(@, @mediaObj)

    @textBox.currentID = parseInt(@mediaObj.start_at)

    start = parseInt(@mediaObj.start_at)
    stop  = parseInt(@mediaObj.end_at)
    @textBox.redraw(start,stop, last_line)
    start = parseFloat($("#jp-"+start).data("start_timecode"))
    stop  = parseFloat($("#jp-"+stop).data("end_timecode"))

    console.log(@mediaObj)

    @$(".jp-jplayer").jPlayer
      solution: "flash, html"
      ready: ->
        $(@).jPlayer "setMedia",
          rtmpv: path + mov
          m4v: path+mov
          poster: "assets/rglossa/speech/_6.6-%27T%27_ligo.skev.graa.jpg"
        $(@).jPlayer( "play", start)

      timeupdate: (event) =>
        ct = event.jPlayer.status.currentTime
        if ct > stop
          @$(".jp-jplayer").jPlayer("play", start)
          @$(".jp-jplayer").jPlayer( "pause" )
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

          @$(".js-jplayer").jPlayer("play", start)


  willDestroyElement: ->
    @$(".jp-jplayer").jPlayer('destroy')


  createTextBox: =>
    start_at_line:0
    end_at_line:0
    currentID:0
    nextID:0
    currentEndTime:0
    currentStartTime:0

    init: (view, mediaObj) ->
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
        .on "click", (e) -> alert($(@).data("start_timecode")+" id:"+$(@).attr("id"))

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
        view.$('.jplayer-text').append(div)


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

