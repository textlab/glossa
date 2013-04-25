App.CurrentPaginatorPageView = Em.TextField.extend
  classNames: 'input-mini'

  # If we bind the value to the currentPageNo of the controller, it will
  # a page change for each key press, causing a page change for each
  # digit in a multi-digit page number. We don't want that, so we rather
  # initialize the value on didInsertElement and use the action event
  # (which is triggered on enter with the page number as argument) to update
  # the page numer in the controller.

  action: 'setCurrentPageNo'

  didInsertElement: ->
    @setValue()
    @$().on 'blur', $.proxy(@setValue, @)

  willDestroyElement: ->
    @$().off 'blur'

  setValue: -> @set('value', @get('controller.currentPageNo'))