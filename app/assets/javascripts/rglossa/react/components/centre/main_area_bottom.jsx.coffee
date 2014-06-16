#= require ./start/start_main
#= require ./results/results_main

###* @jsx React.DOM ###

window.MainAreaBottom = React.createClass
  propTypes:
    store: React.PropTypes.object.isRequired
    statechart: React.PropTypes.object.isRequired
    corpus: React.PropTypes.object.isRequired


  mainComponent: ->
    if @props.statechart.pathContains('start')
      `<StartMain
          store={this.props.store}
          statechart={this.props.statechart}
          corpus={this.props.corpus} />`
    else
      searchId = @props.statechart.getArgumentValue('searchId')
      results = if searchId then @props.store.find('search', searchId) else null
      currentResultPageNo = @props.statechart.getArgumentValue('currentResultPageNo')
      `<ResultsMain
          statechart={this.props.statechart}
          results={results}
          currentResultPageNo={currentResultPageNo} />`


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
