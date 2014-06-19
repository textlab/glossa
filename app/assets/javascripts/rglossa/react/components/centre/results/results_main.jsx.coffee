#= require ../search_inputs/cwb_search_inputs
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

  render: ->
    {store, statechart, results,
      currentResultPageNo, corpus, query, handleQueryChanged} = @props
    resultPage = results.pages[currentResultPageNo]

    # Select components based on the search engine name,
    # e.g. CwbSearchInputs and CwbResultsTable
    searchEngine = corpus.search_engine or 'cwb'
    capSearchEngine = "#{searchEngine[0].toUpperCase() + searchEngine.slice(1)}"
    searchInputs = window["#{capSearchEngine}SearchInputs"]
    resultTable = window["#{capSearchEngine}ResultsTable"]

    `<span>
      <searchInputs
        store={store}
        corpus={corpus}
        statechart={statechart}
        query={query}
        handleQueryChanged={handleQueryChanged} />
      <resultTable resultPage={resultPage} corpus={corpus} />
    </span>`