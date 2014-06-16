#= require ./cwb_results_table

###* @jsx React.DOM ###

window.ResultsMain = React.createClass
  propTypes:
    statechart: React.PropTypes.object.isRequired
    results: React.PropTypes.object.isRequired
    currentResultPageNo: React.PropTypes.number.isRequired
    corpus: React.PropTypes.object.isRequired

  render: ->
    {statechart, results, currentResultPageNo, corpus} = @props
    resultPage = results.pages[currentResultPageNo]

    # Select a component based on the search engine name, e.g. CwbResultsTable
    searchEngine = corpus.search_engine or 'cwb'
    component = window["#{searchEngine[0].toUpperCase() + searchEngine.slice(1)}ResultsTable"]

    component
      resultPage: resultPage
      corpus: corpus
