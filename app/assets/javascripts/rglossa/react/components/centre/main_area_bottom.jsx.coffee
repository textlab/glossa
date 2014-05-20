#= require ./start/start_main
#= require ./results/results_main

###* @jsx React.DOM ###

window.MainAreaBottom = React.createClass
  propTypes:
    statechart: React.PropTypes.object.isRequired
    corpus: React.PropTypes.object.isRequired

  rowWithSidebar: ->
    `<div className="row-fluid">
      <div id="left-sidebar" className="span3">
        METADATA_CATEGORIES
      </div>
      <div id="main-content" className="span9">
        {this.props.statechart.pathContains('start')
          ? <StartMain statechart={this.props.statechart} corpus={this.props.corpus} />
          : <ResultsMain />}
      </div>
    </div>`

  rowWithoutSidebar: ->
    `<div className="row-fluid">
      <div id="main-content" className="span12">
        {this.props.statechart.pathContains('start')
          ? <StartMain statechart={this.props.statechart} corpus={this.props.corpus} />
          : <ResultsMain />}
      </div>
    </div>`

  render: ->
    if true then @rowWithSidebar() else @rowWithoutSidebar()