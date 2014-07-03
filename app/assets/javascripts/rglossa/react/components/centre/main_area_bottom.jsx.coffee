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
    isShowingSidebar: React.PropTypes.bool.isRequired

  handleMetadataSelectionsChanged: ->
    @props.handleSearch()

  handleSidebarHidden: ->
    # When the sidebar is hidden, we make the content area full width. We also need to add
    # the no-sidebar class to remove its left margin (bootstrap removes left margin on the
    # first child with a 'spanX' class, but the transition group containing the sidebar
    # leaves a span in the markup that prevents the main content from becoming the first child).
    $('#main-content', @getDOMNode()).removeClass('span9').addClass('span12 no-sidebar')

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
    ReactTransitionGroup = React.addons.TransitionGroup

    `<div className="row-fluid">
      {this.props.corpus.metadata_categories.length
        ? <ReactTransitionGroup transitionName="sidebar">
            {this.props.isShowingSidebar
              ? <MetadataCategories
                  corpus={this.props.corpus}
                  handleMetadataSelectionsChanged={this.handleMetadataSelectionsChanged}
                  handleSidebarHidden={this.handleSidebarHidden} />
              : []}
          </ReactTransitionGroup>
        : null}
      <div id="main-content" className="span9">
        {this.mainComponent()}
      </div>
    </div>`
