###* @jsx React.DOM ###

window.WFplayer = React.createClass
  componentDidMount: ->
    $node = $(@getDOMNode())
    mediaObj = @props.mediaObj

    $(document).tooltip
      content: -> $node.prop('title')

    corpus_id = mediaObj.corpus_id
    line_key = mediaObj.mov.line_key
    mov = mediaObj.mov.movie_loc
    path = mediaObj.mov.path
    $("#movietitle").text(mediaObj.title)
    start = mediaObj.divs.annotation[parseInt(mediaObj.start_at)].from
    stop  = mediaObj.divs.annotation[parseInt(mediaObj.end_at)].to

    $node.find("#waveframe").attr('src', "wfplayer-#{corpus_id}-#{line_key}-#{start}-#{stop}")

  render: ->
    `<div><iframe height="340" width="90%" id="waveframe" target="_blank" className="wfplayer"></iframe></div>`
