#= require ./start/start_main
#= require ./results/results_main

###* @jsx React.DOM ###

window.MainAreaBottom = React.createClass
  propTypes:
    store: React.PropTypes.object.isRequired
    statechart: React.PropTypes.object.isRequired
    corpus: React.PropTypes.object.isRequired

  rowWithSidebar: (results) ->
    `<div className="row-fluid">
      <div id="left-sidebar" className="span3">
        METADATA_CATEGORIES
      </div>
      <div id="main-content" className="span9">
        {this.props.statechart.pathContains('start')
          ? <StartMain
              store={this.props.store}
              statechart={this.props.statechart}
              corpus={this.props.corpus} />
          : <ResultsMain
              statechart={this.props.statechart}
              results={results} />}
      </div>
    </div>`

  rowWithoutSidebar: (results) ->
    `<div className="row-fluid">
      <div id="main-content" className="span12">
        {this.props.statechart.pathContains('start')
          ? <StartMain
              store={this.props.store}
              statechart={this.props.statechart}
              corpus={this.props.corpus} />
          : <ResultsMain
              statechart={this.props.statechart}
              results={results} />}
      </div>
    </div>`

  render: ->
    searchId = @props.statechart.getArgumentValue('searchId')
    results = if searchId then @props.store.find('search', searchId) else null
    if true then @rowWithSidebar(results) else @rowWithoutSidebar(results)