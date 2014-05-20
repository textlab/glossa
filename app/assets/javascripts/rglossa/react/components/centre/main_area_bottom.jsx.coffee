#= require ./start/start_main
#= require ./results/results_main

###* @jsx React.DOM ###

window.MainAreaBottom = React.createClass
  propTypes:
    statechart: React.PropTypes.object.isRequired
    corpus: React.PropTypes.object.isRequired

  rowWithSidebar: ->
    `<span>
      <div id="left-sidebar" className="span3">
        METADATA_CATEGORIES
      </div>
      <div id="main-content" className="span9">
        {this.props.statechart.pathContains('start')
          ? <StartMain statechart={this.props.statechart} corpus={this.props.corpus} />
          : <ResultsMain />}
      </div>
    </span>`

  rowWithoutSidebar: ->
    `<div id="main-content" className="span12">
      {this.props.statechart.pathContains('start')
        ? <StartMain statechart={this.props.statechart} corpus={this.props.corpus} />
        : <ResultsMain />}
    </div>`

  render: ->
    `<div className="row-fluid">
      {true ? this.rowWithSidebar() : this.rowWithoutSidebar()}
      </div>`