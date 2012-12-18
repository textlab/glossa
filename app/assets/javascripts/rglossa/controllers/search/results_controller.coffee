App.ResultsController = Em.ArrayController.extend
  content: []
  searchBinding: 'currentSearchController.content'

  pageSize: 15

  _currentPageNo: 0
  currentPageNo: ((key, value) ->
    if value?
      numPages = @get('numPages')
      @_currentPageNo = if value < 0 then 0 else (if value >= numPages then numPages - 1 else value)

    @_currentPageNo
  ).property()

  showPreviousPage: ->
    @set('currentPageNo', @get('currentPageNo') - 1)

  showNextPage: ->
    @set('currentPageNo', @get('currentPageNo') + 1)

  showFirstPage: ->
    @set('currentPageNo', 0)

  showLastPage: ->
    @set('currentPageNo', @get('numPages') - 1)

  numPages: (->
    numHits = @get('content.length')
    if numHits is 0 then 0 else Math.floor((numHits - 1) / @pageSize) + 1
  ).property('content.length')

  hasMoreThanOnePage: (->
    @get('numPages') > 1
  ).property('numPages')

  isShowingFirstPage: (->
    @get('currentPageNo') is 0
  ).property('currentPageNo')

  isShowingLastPage: (->
    @get('currentPageNo') is @get('numPages') - 1
  ).property('currentPageNo', 'numPages')
