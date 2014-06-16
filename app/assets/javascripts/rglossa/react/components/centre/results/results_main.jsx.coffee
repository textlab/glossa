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

    # Construct a component name based on the search engine name, e.g. CwbResultsTable
    searchEngine = corpus.search_engine or 'cwb'
    component = "#{searchEngine[0].toUpperCase() + searchEngine.slice(1)}ResultsTable"

    # Render the component whose name we constructed above
    window[component]
      resultPage: resultPage
      corpus: corpus
