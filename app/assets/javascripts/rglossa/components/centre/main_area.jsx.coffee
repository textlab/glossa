#= require rglossa/utils
#= require rglossa/models/corpus
#= require ./main_area_top
#= require ./main_area_bottom

###* @jsx React.DOM ###

window.MainArea = React.createClass
  propTypes:
    store: React.PropTypes.object.isRequired
    statechart: React.PropTypes.object.isRequired
    corpus: React.PropTypes.object.isRequired

  # If the width of the browser window is <= this, we automatically hide the sidebar
  # to make more room for search results.
  maxAutoHideSidebarWidth: 1100

  getInitialState: ->
    searchQueries: @createEmptyQueries()
    selectedMetadataIds: {}
    maxHits: 2000
    lastSelectedMaxHits: null
    sortBy: 'position'
    isShowingSidebar: !!(@props.corpus.metadata_categories.length)
    isNarrowView: false


  createEmptyQueries: ->
    corpus = @props.corpus

    # If the corpus is multilingual, the first query will be associated with the first language
    # in the language list of the corpus. Otherwise, we set the language to 'single'.
    lang = if corpusNs.isMultilingual(corpus) then corpusNs.getLanguages(corpus)[0].lang else 'single'
    [{lang: lang, query: ''}]


  componentDidMount: ->
    # determine if the window is narrow, because then we want to automatically hide
    # the sidebar before showing search results
    @setState(isNarrowView: $('body').width() <= @maxAutoHideSidebarWidth)

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


  statics:
    headwordQueryPrefix: '<headword>'
    headwordQuerySuffixMoreWords: '[]{0,}'
    headwordQuerySuffixTag: '</headword> sort by headword_len'

    convertToHeadwordQuery: (query) ->
      MainArea.headwordQueryPrefix + query + MainArea.headwordQuerySuffixMoreWords + MainArea.headwordQuerySuffixTag

    convertToNonHeadwordQuery: (query) ->
      query = rglossaUtils.withoutSuffix(query, MainArea.headwordQuerySuffixTag)
      query = rglossaUtils.withoutSuffix(query, MainArea.headwordQuerySuffixMoreWords)
      query = rglossaUtils.withoutPrefix(query, MainArea.headwordQueryPrefix)

  handleQueryChanged: (queryIndex, query) ->
    # When the query changes, also set maxHits to the last requested number of
    # hits if we have asked to see all hits in the mean time, in which case
    # @state.maxHits will be null. This way, we will always limit the number of
    # hits each time we do a new query.
    if query.headwordSearch
      query.query = MainArea.convertToHeadwordQuery(query.query)
    else
      query.query = MainArea.convertToNonHeadwordQuery(query.query)

    queries = @state.searchQueries.slice(0)
    queries[queryIndex] = query
    newState = searchQueries: queries

    if !@state.maxHits and @state.lastSelectedMaxHits
      newState.maxHits = @state.lastSelectedMaxHits
    @setState(newState)


  handleAddLanguage: ->
    queries = @state.searchQueries.slice(0)
    languages = corpusNs.getLanguages(@props.corpus)

    # When we add a new language row to the queries, we initialize the row to the first
    # language we find that is not used in any other query (since we cannot have multiple
    # queries in the same language for multilingual searches).
    unusedLanguage = null
    for l in languages
      unless (queries.some (query) -> query.lang is l.lang)
        unusedLanguage = l.lang
        break

    queries.push
      lang: unusedLanguage
      query: ''

    @setState(searchQueries: queries)


  handleAddPhrase: ->
    queries = @state.searchQueries.slice(0)
    queries.push(lang: 'single', query: '')
    @setState(searchQueries: queries)


  handleRemoveRow: (index, e) ->
    e.preventDefault()
    queries = @state.searchQueries.slice(0)
    queries.splice(index, 1)
    @setState(searchQueries: queries)


  handleMaxHitsChanged: (maxHits) ->
    newState = maxHits: maxHits
    if maxHits is null and @state.maxHits
      # if we ask for all hits, remember what number of hits we asked for
      # last time so that we can use the same number when doing the next search
      newState.lastSelectedMaxHits = @state.maxHits

    @setState(newState)
    @handleSearch(newState)


  handleResetSearchForm: ->
    @setState
      searchQueries: @createEmptyQueries()
      selectedMetadataIds: {}

    @props.statechart.handleAction('resetSearchForm')


  handleMetadataSelectionsChanged: (selectedMetadataIds) ->
    newState = {selectedMetadataIds: selectedMetadataIds}
    @setState(newState)
    @handleSearch(newState)


  handleSortByChanged: (sortBy, e) ->
    e.preventDefault()
    newState = {sortBy: sortBy}
    @setState(newState)
    @handleSearch(newState)


  handleSearch: (newState = {}) ->
    state = rglossaUtils.merge(@state, newState)
    firstQueryString = state.searchQueries[0].query
    return unless firstQueryString and firstQueryString isnt '""'

    {store, statechart, corpus} = @props

    searchEngine = corpus.search_engine ?= 'cwb'
    searchUrl = "search_engines/#{searchEngine}_searches"

    $.ajax(
      url: searchUrl
      method: 'POST'
      data: JSON.stringify
        corpus_short_name: corpus.short_name
        queries: state.searchQueries
        metadata_value_ids: state.selectedMetadataIds
        max_hits: state.maxHits
        sortBy: state.sortBy
      dataType: 'json'
      contentType: 'application/json'
    ).then (res) =>
      searchModel = "#{searchEngine}_search"
      search = res[searchModel]
      id = search.id

      if !@state.maxHits or (search.num_hits and search.num_hits < @state.maxHits)
        # There were fewer than maxHits occurrences in the corpus
        search.total = search.num_hits
      else
        # Either there were at least maxHits occurrences in the corpus, or num_hits
        # was not set on the result (because we're searching in a multipart corpus).
        # In either case, find out the total number of occurrences.
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

    if @state.isShowingSidebar and @state.isNarrowView
      # automatically hide the sidebar before showing results if the window is narrow
      @toggleSidebar(false)

    # Show the result page with empty search results so that a spinner
    # will be shown until the new results are received from the server
    statechart.handleAction('showResults', null)


  render: ->
    {store, statechart, corpus} = @props
    {searchQueries, maxHits, sortBy, isShowingSidebar} = @state

    searchId = statechart.getValue('searchId')
    results = if searchId then store.find('search', searchId) else null

    `<span>
      <div className="container-fluid" style={{paddingLeft: 45}}>

        <MainAreaTop
          statechart={statechart}
          corpus={corpus}
          results={results}
          maxHits={maxHits}
          handleMaxHitsChanged={this.handleMaxHitsChanged}
          isShowingSidebar={isShowingSidebar}
          toggleSidebar={this.toggleSidebar}
          handleResetSearchForm={this.handleResetSearchForm} />

        <MainAreaBottom
          store={store}
          statechart={statechart}
          corpus={corpus}
          results={results}
          searchQueries={searchQueries}
          handleQueryChanged={this.handleQueryChanged}
          sortBy={sortBy}
          handleSortByChanged={this.handleSortByChanged}
          maxHits={maxHits}
          handleSearch={this.handleSearch}
          handleAddLanguage={this.handleAddLanguage}
          handleAddPhrase={this.handleAddPhrase}
          handleRemoveRow={this.handleRemoveRow}
          handleMetadataSelectionsChanged={this.handleMetadataSelectionsChanged}
          isShowingSidebar={isShowingSidebar}
          isMetadataSelectionEmpty={Object.keys(this.state.selectedMetadataIds).length === 0} />
      </div>
    </span>`
