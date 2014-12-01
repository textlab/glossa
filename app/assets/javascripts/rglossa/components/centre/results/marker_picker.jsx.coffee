###* @jsx React.DOM ###

window.MarkerPicker = React.createClass
  propTypes:
    data: React.PropTypes.object
    addMarkers: React.PropTypes.func.isRequired

  getPhons: ->
    if @props.data?
      Object.keys(@props.data.phons_per_place).filter (key) -> key isnt '_'
    else []


  componentDidUpdate: ->
    return unless @props.data
    for phon in @getPhons()
      $("#phon_#{phon}").colorpicker
        label: phon
        func: (a, id) => @props.addMarkers(a, id)


  render: ->
    phons = @getPhons()

    `<div className="distr-legend" id="legend0" style={{float: 'left', overflowY: 'auto'}}>
    {phons.map(function(phon) {
      return (
        <span key={phon}>
          <a id={'phon_' + phon} data-phon-link style={{position: 'absolute', left: -10000}}>{phon}</a>
        </span>
      )
    })}
    </div>`
