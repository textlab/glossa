#= require ../../../statechart

###* @jsx React.DOM ###

# Search inputs for corpora encoded with the IMS Corpus Workbench

root =
  initialSubstate: 'simple'
  substates:
    simple: {}
    multiword: {}
    regex: {}
  actions:
    showMultiword: -> @transitionTo('multiword')

window.CwbSearchInputs = React.createClass
  getInitialState: ->
    statechart: new Statechart(
      'CwbSearchInputs', root, (sc) => @setState(statechart: sc))

  render: ->
    if @state.statechart.pathContains('simple')
      `<span>
        <div className="row-fluid search-input-links">
          <b>Simple</b>&nbsp;|&nbsp;
          <a href="" title="Search for grammatical categories etc.">Extended</a>&nbsp;|&nbsp;
          <a href="" title="Regular expressions">Regexp</a>
        </div>
      </span>`

    else if @state.statechart.pathContains('multiword')
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
