#= require rglossa/react/utils
#= require ../search_inputs/cwb_search_inputs
#= require ./results_toolbar
#= require ./cwb_results_table

###* @jsx React.DOM ###

window.ResultsMain = React.createClass
  propTypes:
    store: React.PropTypes.object.isRequired
    statechart: React.PropTypes.object.isRequired
    results: React.PropTypes.object
    currentResultPageNo: React.PropTypes.number.isRequired
    corpus: React.PropTypes.object.isRequired
    searchQuery: React.PropTypes.string.isRequired
    handleQueryChanged: React.PropTypes.func.isRequired
    maxHits: React.PropTypes.number.isRequired
    handleSearch: React.PropTypes.func.isRequired

  render: ->
    {store, statechart, results, currentResultPageNo, corpus, searchQuery,
        handleQueryChanged, maxHits, handleSearch} = @props
    resultPage = results?.pages[currentResultPageNo]

    # Select components based on the search engine name,
    # e.g. CwbSearchInputs and CwbResultsTable
    searchEngine = corpus.search_engine or 'cwb'
    capSearchEngine = rglossaUtils.capitalize(searchEngine)
    searchInputs = window["#{capSearchEngine}SearchInputs"]
    resultTable = window["#{capSearchEngine}ResultsTable"]

    `<span>
      <searchInputs
        store={store}
        corpus={corpus}
        statechart={statechart}
        searchQuery={searchQuery}
        handleQueryChanged={handleQueryChanged}
        maxHits={maxHits}
        handleSearch={handleSearch} />
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