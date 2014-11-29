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
    searchQueries: React.PropTypes.array.isRequired
    handleQueryChanged: React.PropTypes.func.isRequired
    sortBy: React.PropTypes.string.isRequired
    handleSortByChanged: React.PropTypes.func.isRequired
    maxHits: React.PropTypes.number
    handleSearch: React.PropTypes.func.isRequired
    handleMetadataSelectionsChanged: React.PropTypes.func.isRequired
    isShowingSidebar: React.PropTypes.bool.isRequired
    isMetadataSelectionEmpty: React.PropTypes.bool.isRequired
    handleAddLanguage: React.PropTypes.func.isRequired
    handleAddPhrase: React.PropTypes.func.isRequired
    handleRemoveRow: React.PropTypes.func.isRequired

  handleSidebarHidden: ->
    # When the sidebar is hidden, we make the content area full width. We also need to add
    # the no-sidebar class to remove its left margin (bootstrap removes left margin on the
    # first child with a 'spanX' class, but the transition group containing the sidebar
    # leaves a span in the markup that prevents the main content from becoming the first child).
    $('#main-content', @getDOMNode()).removeClass('span9').addClass('span12 no-sidebar')

  mainComponent: ->
    {store, statechart, corpus, results, searchQueries, handleQueryChanged, sortBy,
    handleSortByChanged, handleAddLanguage,  handleAddPhrase, handleRemoveRow,
    maxHits, handleSearch} = @props
    if statechart.pathContains('start')
      `<StartMain
          store={store}
          statechart={statechart}
          corpus={corpus}
          searchQueries={searchQueries}
          handleQueryChanged={handleQueryChanged}
          handleSearch={handleSearch}
          handleAddLanguage={handleAddLanguage}
          handleAddPhrase={handleAddPhrase}
          handleRemoveRow={handleRemoveRow} />`
    else
      currentResultPageNo = statechart.getValue('currentResultPageNo')
      `<ResultsMain
          store={store}
          statechart={statechart}
          results={results}
          currentResultPageNo={currentResultPageNo}
          corpus={corpus}
          searchQueries={searchQueries}
          handleQueryChanged={handleQueryChanged}
          sortBy={sortBy}
          handleSortByChanged={handleSortByChanged}
          handleAddLanguage={handleAddLanguage}
          handleAddPhrase={handleAddPhrase}
          handleRemoveRow={handleRemoveRow}
          maxHits={maxHits}
          handleSearch={handleSearch} />`


  render: ->
    ReactTransitionGroup = React.addons.TransitionGroup

    `<div className="row-fluid">
      {this.props.corpus.metadata_categories.length
        ? <ReactTransitionGroup transitionName="sidebar">
            {this.props.isShowingSidebar
              ? <MetadataCategories
                  isMetadataSelectionEmpty={this.props.isMetadataSelectionEmpty}
                  corpus={this.props.corpus}
                  handleMetadataSelectionsChanged={this.props.handleMetadataSelectionsChanged}
                  handleSidebarHidden={this.handleSidebarHidden} />
              : []}
          </ReactTransitionGroup>
        : null}
      <div id="main-content" className={this.props.corpus.metadata_categories.length ? 'span9' : 'span12'}>
        {this.mainComponent()}
      </div>
    </div>`
