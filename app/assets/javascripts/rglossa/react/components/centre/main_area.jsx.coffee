#= require rglossa/react/utils
#= require ./main_area_top
#= require ./main_area_bottom

###* @jsx React.DOM ###

window.MainArea = React.createClass
  propTypes:
    store: React.PropTypes.object.isRequired
    statechart: React.PropTypes.object.isRequired
    corpus: React.PropTypes.object.isRequired

  getInitialState: ->
    searchQuery: ''
    maxHits: 2000
    lastSelectedMaxHits: null
    isShowingSidebar: true

  # Transitioning the toggling of the sidebar requires several steps because we need to
  # coordinate the sizing of the sidebar and the main content area (otherwise, we could
  # probably just have used React.addons.CSSTransitionGroup):
  # 1) Use React.addons.TransitionGroup, which provides some extra lifecycle hooks on
  #    MetadataCategories
  # 2) If the sidebar is being shown, decrease the width of the main content area in
  #    toggleSidebar(); otherwise, do nothing
  # 3) If the sidebar is being hidden, use componentWillLeave() and componentDidLeave() in
  #    MetadataCategories to transition its width to zero and then call handleSidebarHidden()
  #    in MainAreaBottom to increase the width of the main content area when the transition
  #    is done. If, on the other hand, the sidebar is being shown, use componentWillEnter() and
  #    componentDidEnter() to transition the width of the sidebar from zero to span3.
  #
  # The animation mechanisms in React are under development, and we can hopefully change this
  # procedure to something simpler (and more unified) in the future.
  toggleSidebar: (shouldShow) ->
    if shouldShow
      $('#main-content', @getDOMNode()).removeClass('span12 no-sidebar').addClass('span9')

    @setState(isShowingSidebar: shouldShow)


  handleQueryChanged: (query) ->
    # When the query changes, also set maxHits to the last requested number of
    # hits if we have asked to see all hits in the mean time, in which case
    # @state.maxHits will be null. This way, we will always limit the number of
    # hits each time we do a new query.
    newState = searchQuery: query
    if !@state.maxHits and @state.lastSelectedMaxHits
      newState.maxHits = @state.lastSelectedMaxHits
    @setState(newState)

  handleMaxHitsChanged: (maxHits) ->
    newState = maxHits: maxHits
    if maxHits is null and @state.maxHits
      # if we ask for all hits, remember what number of hits we asked for
      # last time so that we can use the same number when doing the next search
      newState.lastSelectedMaxHits = @state.maxHits

    @setState(newState)
    @handleSearch(newState)


  resetSearchForm: ->
    @setState(searchQuery: '')
    @props.statechart.handleAction('resetSearchForm')


  handleSearch: (newState = {}) ->
    state = rglossaUtils.merge(@state, newState)
    return unless state.searchQuery and state.searchQuery isnt '""'

    {store, statechart, corpus} = @props

    # Remove any previous search results so that a spinner will be
    # shown until the new results are received from the server
    statechart.changeValue('searchId', null, true)

    searchEngine = corpus.search_engine ?= 'cwb'
    searchUrl = "search_engines/#{searchEngine}_searches"
    query =
      query: state.searchQuery
      corpusShortName: corpus.short_name

    $.ajax(
      url: searchUrl
      method: 'POST'
      data: JSON.stringify
        queries: [query]
        max_hits: state.maxHits
      dataType: 'json'
      contentType: 'application/json'
    ).then (res) =>
      searchModel = "#{searchEngine}_search"
      search = res[searchModel]
      id = search.id

      if !@state.maxHits or search.num_hits < @state.maxHits
        # There were fewer than maxHits occurrences in the corpus
        search.total = search.num_hits
      else
        # There were at least maxHits occurrences in the corpus; find out the total
        $.getJSON("#{searchUrl}/#{id}/count").then (count) =>
          # Update the search model in the store with the total
          model = store.find('search', id)
          model.total = count
          store.setData('search', id, model)

      search.pages = search.first_two_result_pages

      delete search.pages['2'] if search.pages['2'].length is 0
      delete search.first_two_result_pages

      store.setData('search', id, search)
      statechart.handleAction('showResults', id)

    statechart.handleAction('showResults', null)


  render: ->
    {store, statechart, corpus} = @props
    {searchQuery, maxHits, isShowingSidebar} = @state

    searchId = statechart.getValue('searchId')
    results = if searchId then store.find('search', searchId) else null

    `<span>
      <div className="container-fluid">

        <MainAreaTop
          statechart={statechart}
          corpus={corpus}
          results={results}
          maxHits={maxHits}
          handleMaxHitsChanged={this.handleMaxHitsChanged}
          isShowingSidebar={isShowingSidebar}
          toggleSidebar={this.toggleSidebar}
          resetSearchForm={this.resetSearchForm} />

        <MainAreaBottom
          store={store}
          statechart={statechart}
          corpus={corpus}
          results={results}
          searchQuery={searchQuery}
          handleQueryChanged={this.handleQueryChanged}
          maxHits={maxHits}
          handleSearch={this.handleSearch}
          isShowingSidebar={isShowingSidebar} />
      </div>
    </span>`
