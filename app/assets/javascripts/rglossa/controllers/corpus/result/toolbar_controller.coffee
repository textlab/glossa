App.ResultToolbarController = Em.ArrayController.extend
  needs: ['search', 'corpus']

  search: null
  searchBinding: 'controllers.search.model'

  corpus: null
  corpusBinding: 'controllers.corpus.model'

  pageSize: 15

  _currentPageNo: 1
  currentPageNo: ((key, value) ->
    if value?
      value = parseInt(value)
      numPages = @get('numPages')
      @_currentPageNo = if value < 1 then 1 else (if numPages > 0 and value > numPages then numPages else value)

    @_currentPageNo
  ).property()

  setCurrentPageNo: (pageNo) ->
    @set('currentPageNo', pageNo)

  showPreviousPage: ->
    @set('currentPageNo', @get('currentPageNo') - 1)

  showNextPage: ->
    @set('currentPageNo', @get('currentPageNo') + 1)

  showFirstPage: ->
    @set('currentPageNo', 1)

  showLastPage: ->
    @set('currentPageNo', @get('numPages'))

  numPages: (->
    numHits = @get('search.numHits')
    if numHits is 0 then 0 else Math.floor((numHits - 1) / @pageSize) + 1
  ).property('search.numHits')

  hasMoreThanOnePage: (->
    @get('numPages') > 1
  ).property('numPages')

  isShowingFirstPage: (->
    @get('currentPageNo') is 1
  ).property('currentPageNo')

  isShowingLastPage: (->
    @get('currentPageNo') is @get('numPages')
  ).property('currentPageNo', 'numPages')

  changeResultPage: (->
    @get('target').send 'showResult',
      corpus: @get('corpus')
      search: @get('search')
      pageNo: @get('currentPageNo')
  ).observes('currentPageNo')
