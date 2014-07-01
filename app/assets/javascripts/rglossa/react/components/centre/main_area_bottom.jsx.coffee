#= require ./start/start_main
#= require ../left/metadata_categories
#= require ./results/results_main

###* @jsx React.DOM ###

window.MainAreaBottom = React.createClass
  propTypes:
    store: React.PropTypes.object.isRequired
    statechart: React.PropTypes.object.isRequired
    corpus: React.PropTypes.object.isRequired
    results: React.PropTypes.object
    searchQuery: React.PropTypes.string.isRequired
    handleQueryChanged: React.PropTypes.func.isRequired
    maxHits: React.PropTypes.number
    handleSearch: React.PropTypes.func.isRequired

  handleMetadataSelectionsChanged: ->
    @props.handleSearch()

  mainComponent: ->
    {store, statechart, corpus, results, searchQuery, handleQueryChanged, maxHits, handleSearch} = @props
    if statechart.pathContains('start')
      `<StartMain
          store={store}
          statechart={statechart}
          corpus={corpus}
          searchQuery={searchQuery}
          handleQueryChanged={handleQueryChanged}
          handleSearch={handleSearch} />`
    else
      currentResultPageNo = statechart.getValue('currentResultPageNo')
      `<ResultsMain
          store={store}
          statechart={statechart}
          results={results}
          currentResultPageNo={currentResultPageNo}
          corpus={corpus}
          searchQuery={searchQuery}
          handleQueryChanged={handleQueryChanged}
          maxHits={maxHits}
          handleSearch={handleSearch} />`


  render: ->
    `<div className="row-fluid">
      {true
        ? <MetadataCategories
            corpus={this.props.corpus}
            handleMetadataSelectionsChanged={this.handleMetadataSelectionsChanged} />
        : null}
      <div id="main-content" className="span9">
        {this.mainComponent()}
      </div>
    </div>`
