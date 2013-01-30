App.ResultToolbarController = Em.ArrayController.extend
  needs: ['search', 'corpus']

  search: null
  searchBinding: 'controllers.search.model'

  corpus: null
  corpusBinding: 'controllers.corpus.model'

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
    @changeResultPage()

  showNextPage: ->
    @set('currentPageNo', @get('currentPageNo') + 1)
    @changeResultPage()

  showFirstPage: ->
    @set('currentPageNo', 0)
    @changeResultPage()

  showLastPage: ->
    @set('currentPageNo', @get('numPages') - 1)
    @changeResultPage()

  numPages: (->
    numHits = @get('search.numHits')
    if numHits is 0 then 0 else Math.floor((numHits - 1) / @pageSize) + 1
  ).property('search')

  hasMoreThanOnePage: (->
    @get('numPages') > 1
  ).property('numPages')

  isShowingFirstPage: (->
    @get('currentPageNo') is 0
  ).property('currentPageNo')

  isShowingLastPage: (->
    @get('currentPageNo') is @get('numPages') - 1
  ).property('currentPageNo', 'numPages')


  changeResultPage: ->
    @get('target').send 'showResult',
        corpus: @get('corpus')
        search: @get('search')
        pageNo: @get('currentPageNo')
