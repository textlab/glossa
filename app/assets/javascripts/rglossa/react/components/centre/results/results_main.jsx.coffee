#= require rglossa/react/utils
#= require ../search_inputs/cwb_search_inputs
#= require ./results_toolbar
#= require ./cwb_results_table

###* @jsx React.DOM ###

window.ResultsMain = React.createClass
  propTypes:
    store: React.PropTypes.object.isRequired
    statechart: React.PropTypes.object.isRequired
    results: React.PropTypes.object.isRequired
    currentResultPageNo: React.PropTypes.number.isRequired
    corpus: React.PropTypes.object.isRequired
    query: React.PropTypes.string.isRequired
    handleQueryChanged: React.PropTypes.func.isRequired
    maxHits: React.PropTypes.number.isRequired

  render: ->
    {store, statechart, results, currentResultPageNo, corpus, query,
        handleQueryChanged, maxHits} = @props
    resultPage = results.pages[currentResultPageNo]

    # Select components based on the search engine name,
    # e.g. CwbSearchInputs and CwbResultsTable
    searchEngine = corpus.search_engine or 'cwb'
    capSearchEngine = capitalize(searchEngine)
    searchInputs = window["#{capSearchEngine}SearchInputs"]
    resultTable = window["#{capSearchEngine}ResultsTable"]

    `<span>
      <searchInputs
        store={store}
        corpus={corpus}
        statechart={statechart}
        query={query}
        handleQueryChanged={handleQueryChanged}
        maxHits={maxHits} />
      <ResultsToolbar
        store={store}
        statechart={statechart}
        corpus={corpus}
        results={results}
        currentResultPageNo={currentResultPageNo} />
      <resultTable
        resultPage={resultPage}
        corpus={corpus} />
    </span>`