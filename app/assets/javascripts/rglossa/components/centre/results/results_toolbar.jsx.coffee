#= require rglossa/utils
#= require ./results_paginator

###* @jsx React.DOM ###

window.ResultsToolbar = React.createClass
  propTypes:
    store: React.PropTypes.object.isRequired
    statechart: React.PropTypes.object.isRequired
    corpus: React.PropTypes.object.isRequired
    results: React.PropTypes.object
    currentResultPageNo: React.PropTypes.number.isRequired
    showFrequencies: React.PropTypes.func.isRequired

  hasMultipleResultPages: ->
    @props.results and (Object.keys(@props.results.pages).length > 1)

  render: ->
    {store, statechart, corpus, results, currentResultPageNo, showFrequencies} = @props

    `<div className="row-fluid search-result-toolbar" style={{marginTop: 15}}>
      <div className="dropdown pull-left">
        <a className="btn dropdown-toggle" data-toggle="dropdown" href="#">
          Statistics
          &nbsp;<span className="caret"></span>
        </a>
        <ul className="dropdown-menu">
          <li className="dropdown-submenu">
            <a onClick={showFrequencies.bind(null, 'word')} href="#">Frequencies</a>
              <ul className="dropdown-menu">
                  <li><a onClick={showFrequencies.bind(null, 'word')}>Word forms</a></li>
                  <li><a onClick={showFrequencies.bind(null, 'lemma')}>Lemmas</a></li>
              </ul>
          </li>
        </ul>
      </div>
      {this.hasMultipleResultPages()
        ? <ResultsPaginator
            store={store}
            statechart={statechart}
            corpus={corpus}
            results={results}
            currentResultPageNo={currentResultPageNo} />
        : null}
    </div>`