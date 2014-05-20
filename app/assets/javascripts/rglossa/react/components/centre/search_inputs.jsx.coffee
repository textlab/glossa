###* @jsx React.DOM ###

window.SearchInputs = React.createClass
  propTypes:
    statechart: React.PropTypes.object.isRequired

  render: ->
    if @props.statechart.pathContains('simple')
      `<span>
        <div className="row-fluid search-input-links">
          <b>Simple</b>&nbsp;|&nbsp;
          <a href="" title="Search for grammatical categories etc.">Extended</a>&nbsp;|&nbsp;
          <a href="" title="Regular expressions">Regexp</a>
        </div>
      </span>`

    else if @props.statechart.pathContains('multiword')
      `<span>
        <div className="row-fluid search-input-links">
          <a href="" title="Simple search box">Simple</a>&nbsp;|&nbsp;
          <b>Extended</b>&nbsp;|&nbsp;
          <a href="" title="Regular expressions">Regexp</a>
        </div>
      </span>`

    else
      `<span>
        <div className="row-fluid search-input-links">
          <a href="" title="Simple search box">Simple</a>&nbsp;|&nbsp;
          <a href="" title="Search for grammatical categories etc.">Extended</a>&nbsp;|&nbsp;
          <b>Regexp</b>
        </div>
      </span>`
