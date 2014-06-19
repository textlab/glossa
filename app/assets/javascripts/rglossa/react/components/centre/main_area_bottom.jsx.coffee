#= require ./start/start_main
#= require ./results/results_main

###* @jsx React.DOM ###

window.MainAreaBottom = React.createClass
  propTypes:
    store: React.PropTypes.object.isRequired
    statechart: React.PropTypes.object.isRequired
    corpus: React.PropTypes.object.isRequired
    results: React.PropTypes.object

  getInitialState: ->
    query: ''

  handleQueryChanged: (query) ->
    @setState(query: query)

  mainComponent: ->
    {store, statechart, corpus, results} = @props
    if statechart.pathContains('start')
      `<StartMain
          store={store}
          statechart={statechart}
          corpus={corpus}
          query={this.state.query}
          handleQueryChanged={this.handleQueryChanged} />`
    else
      currentResultPageNo = statechart.getArgumentValue('currentResultPageNo')
      `<ResultsMain
          store={store}
          statechart={statechart}
          results={results}
          currentResultPageNo={currentResultPageNo}
          corpus={corpus}
          query={this.state.query}
          handleQueryChanged={this.handleQueryChanged} />`


  rowWithSidebar: ->
    `<div className="row-fluid">
      <div id="left-sidebar" className="span3">
        METADATA_CATEGORIES
      </div>
      <div id="main-content" className="span9">
        {this.mainComponent()}
      </div>
    </div>`


  rowWithoutSidebar: ->
    `<div className="row-fluid">
      <div id="main-content" className="span12">
        {this.mainComponent()}
      </div>
    </div>`


  render: ->
    if true
      @rowWithSidebar()
    else
      @rowWithoutSidebar()
