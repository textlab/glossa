#= require rglossa/utils
#= require ./results_paginator
#= require rglossa/models/corpus

###* @jsx React.DOM ###

window.ResultsToolbar = React.createClass
  propTypes:
    store: React.PropTypes.object.isRequired
    statechart: React.PropTypes.object.isRequired
    corpus: React.PropTypes.object.isRequired
    results: React.PropTypes.object
    currentResultPageNo: React.PropTypes.number.isRequired
    sortBy: React.PropTypes.string.isRequired
    handleSortByChanged: React.PropTypes.func.isRequired
    showFrequencies: React.PropTypes.func.isRequired

  hasMultipleResultPages: ->
    @props.results and (Object.keys(@props.results.pages).length > 1)

  render: ->
    {store, statechart, corpus, results, currentResultPageNo, sortBy,
      handleSortByChanged, showFrequencies} = @props

    `<div className="row-fluid search-result-toolbar" style={{marginTop: 15}}>
      <div className="dropdown pull-left" style={{marginRight: 10}}>
        <a className="btn dropdown-toggle" data-toggle="dropdown" href="#">
          Sort
          &nbsp;<span className="caret"></span>
        </a>
        <ul className="dropdown-menu">
          <li><a onClick={handleSortByChanged.bind(null, 'position')} href="#">
            {sortBy === 'position' && <i className="icon-ok">&nbsp;</i>}By corpus position</a></li>
          <li><a onClick={handleSortByChanged.bind(null, 'match')} href="#">
            {sortBy === 'match' && <i className="icon-ok">&nbsp;</i>}By match</a></li>
          <li><a onClick={handleSortByChanged.bind(null, 'left')} href="#">
            {sortBy === 'left' && <i className="icon-ok">&nbsp;</i>}By left context</a></li>
          <li><a onClick={handleSortByChanged.bind(null, 'right')} href="#">
            {sortBy === 'right' && <i className="icon-ok">&nbsp;</i>}By right context</a></li>
        </ul>
      </div>
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
                  <li><a onClick={showFrequencies.bind(null, corpusNs.getPOSAttribute(corpus))}>Parts-of-speech</a></li>
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
            sortBy={sortBy}
            currentResultPageNo={currentResultPageNo} />
        : null}
    </div>`