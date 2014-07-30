###* @jsx React.DOM ###

window.ResultsPaginator = React.createClass
  propTypes:
    store: React.PropTypes.object.isRequired
    statechart: React.PropTypes.object.isRequired
    corpus: React.PropTypes.object.isRequired
    results: React.PropTypes.object
    currentResultPageNo: React.PropTypes.number.isRequired

  getInitialState: ->
    displayedPageNo: @props.currentResultPageNo  # see comments in handlePageNoChanged below

  componentWillReceiveProps: (nextProps) ->
    if nextProps.currentResultPageNo isnt @state.displayedPageNo
      # see comments in handlePageNoChanged below for why we need displayedPageNo
      @setState(displayedPageNo: nextProps.currentResultPageNo)

  getNumPages: ->
    pageLength = @props.results?.pages['1'].length
    if pageLength then Math.ceil(@props.results.num_hits / pageLength) else 0

  handlePageNoChanged: (e) ->
    # We cannot send the e argument directly into the debounced function,
    # because it may (and will) be changed by React before the debounced
    # function is finally called. Instead, we extract the value we're
    # interested in and store it in a variable that no-one else will mutate.
    pageNo = parseInt(e.target.value)
    unless isNaN(pageNo)
      # Set displayedPageNo right away so that the text box shows the updated number...
      @setState(displayedPageNo: e.target.value)
      # ...but debounce the actual switching to a new page in order to give the user
      # time to finish writing the new page number
      @debouncedHandlePageNoChanged(pageNo)

  debouncedHandlePageNoChanged: rglossaUtils.debounce ((pageNo) -> @setCurrentPageNo(pageNo)), 500

  handlePageNoClicked: ->
    @refs.pageNoInput.getDOMNode().select()

  showFirstPage: ->
    @setCurrentPageNo(1)

  showPreviousPage: ->
    @setCurrentPageNo(@props.currentResultPageNo - 1)

  showNextPage: ->
    @setCurrentPageNo(@props.currentResultPageNo + 1)

  showLastPage: ->
    @setCurrentPageNo(@getNumPages())

  setCurrentPageNo: (pageNo) ->
    {store, statechart, corpus, results, currentResultPageNo} = @props

    return unless results

    numPages = @getNumPages()
    clippedPageNo = if pageNo < 1 then 1 else (if numPages > 0 and pageNo > numPages then numPages else pageNo)

    if clippedPageNo isnt currentResultPageNo
      if results.pages[clippedPageNo]
        statechart.changeValue('currentResultPageNo', clippedPageNo)
      else
        searchEngine = corpus.search_engine or 'cwb'
        url = "search_engines/#{searchEngine}_searches/#{results.id}/results?pages[]=#{clippedPageNo}
          &current_corpus_part=#{results.current_corpus_part}"
        $.getJSON(url).done (res) ->
          {search_id, pages} = res.search_results
          model = store.find('search', search_id)
          model.pages[clippedPageNo] = pages[clippedPageNo]
          store.setData('search', search_id, model)
          statechart.changeValue('currentResultPageNo', clippedPageNo)


  render: ->
    numPages    = @getNumPages()
    isFirstPage = @props.currentResultPageNo is 1
    isLastPage  = @props.currentResultPageNo is numPages

    `<div className="pagination pagination-right">
      <ul>
        <li className={isFirstPage ? 'disabled' : ''}>
          <a href="#" onClick={this.showFirstPage}>««</a>
        </li>
        <li className={isFirstPage ? 'disabled' : ''}>
          <a href="#" onClick={this.showPreviousPage}>«</a>
        </li>
        <li><span>Page</span></li>
        <li><span className="paginator-counter">
          <input ref="pageNoInput" type="text" className="input-mini" value={this.state.displayedPageNo}
            onClick={this.handlePageNoClicked} onChange={this.handlePageNoChanged} /></span>
        </li>
        <li><span>of {numPages} pages</span></li>
        <li className={isLastPage ? 'disabled' : ''}>
          <a href="#" onClick={this.showNextPage}>»</a>
        </li>
        <li className={isLastPage ? 'disabled' : ''}>
          <a href="#" onClick={this.showLastPage}>»»</a>
        </li>
      </ul>
    </div>`
