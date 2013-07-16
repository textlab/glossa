App.CurrentPaginatorPageView = Em.TextField.extend
  classNames: 'input-mini'

  # If we use a two-way binding from the value to the currentPageNo of the
  # controller, it will cause a page change for each key press, meaning a page
  # change for each digit in a multi-digit page number. We don't want that, so
  # we rather use a one-way binding and then initialize the value on
  # didInsertElement and use the action event (which is triggered on enter with
  # the page number as argument) to update the page number in the controller.

  valueBinding: Em.Binding.oneWay('controller.currentPageNo')

  action: 'setCurrentPageNo'

  didInsertElement: ->
    @setValue()
    @$().on 'blur', $.proxy(@setValue, @)

  willDestroyElement: ->
    @$().off 'blur'

  setValue: -> @set('value', @get('controller.currentPageNo'))
