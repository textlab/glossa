#= require rglossa/react/utils
#= require ./results_paginator

###* @jsx React.DOM ###

window.ResultsToolbar = React.createClass
  propTypes:
    store: React.PropTypes.object.isRequired
    statechart: React.PropTypes.object.isRequired
    corpus: React.PropTypes.object.isRequired
    results: React.PropTypes.object
    currentResultPageNo: React.PropTypes.number.isRequired

  hasMultipleResultPages: ->
    @props.results and (Object.keys(@props.results.pages).length > 1)

  render: ->
    {store, statechart, corpus, results, currentResultPageNo} = @props

    `<div className="row-fluid search-result-toolbar">
      <div className="pull-left"></div>
      {this.hasMultipleResultPages()
        ? <ResultsPaginator
            store={store}
            statechart={statechart}
            corpus={corpus}
            results={results}
            currentResultPageNo={currentResultPageNo} />
        : null}
    </div>`