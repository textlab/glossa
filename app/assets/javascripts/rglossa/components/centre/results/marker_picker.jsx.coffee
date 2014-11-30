###* @jsx React.DOM ###

window.MarkerPicker = React.createClass
  propTypes:
    data: React.PropTypes.object

  render: ->
    phons = if @props.data?
      Object.keys(@props.data.phons_per_place).filter (key) -> key isnt '_'
    else []

    `<div className="distr-legend" id="legend0" style={{float: 'left'}}>
    {phons.map(function(phon) {
      return (
        <span key="phon">
          <a id="a_0" style={{position: 'absolute', left: -10000}}>phon</a>
          <div className="colorpicker-wrap">
            <div className="colorpicker-label">{phon}</div>
            <div className="colorpicker-trigger" style={{backgroundColor: 'rgb(221, 221, 221)'}} />
            <div style={{width: 100}} className="colorpicker-picker">
              <span className="colorpicker-picker-span " rel="white" style={{backgroundColor: 'white', width: 20, height: 20}} />
              <span className="colorpicker-picker-span " rel="red" style={{backgroundColor: 'red', width: 20, height: 20}} />
              <span className="colorpicker-picker-span " rel="orange" style={{backgroundColor: 'orange', width: 20, height: 20}} />
              <span className="colorpicker-picker-span " rel="yellow" style={{backgroundColor: 'yellow', width: 20, height: 20}} />
              <span className="colorpicker-picker-span " rel="green" style={{backgroundColor: 'green', width: 20, height: 20}} />
              <span className="colorpicker-picker-span " rel="blue" style={{backgroundColor: 'blue', width: 20, height: 20}} />
              <span className="colorpicker-picker-span " rel="purple" style={{backgroundColor: 'purple', width: 20, height: 20}} />
              <span className="colorpicker-picker-span " rel="black" style={{backgroundColor: 'black', width: 20, height: 20}} />
              <span className="colorpicker-picker-span " rel="#ddd" style={{backgroundColor: '#ddd', width: 20, height: 20}} />
            </div>
            <div style={{clear: 'both'}} />
          </div>
        </span>
      )
    })}
    </div>`
