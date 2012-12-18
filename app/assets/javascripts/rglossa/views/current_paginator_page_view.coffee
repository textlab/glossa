App.CurrentPaginatorPageView = Em.TextField.extend
  classNames: 'input-mini'
  valueBinding: 'displayedValue'

  # The currentPageNo property of the controller is zero-based, but we should
  # display a 1-based page number
  displayedValue: ((key, value) ->
    if value?
      @set('controller.currentPageNo', value - 1)
    @get('controller.currentPageNo') + 1
  ).property('controller.currentPageNo')