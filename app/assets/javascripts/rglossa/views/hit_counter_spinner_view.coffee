#= require rglossa/views/spinner_view

App.HitCounterSpinnerView = Em.View.extend
  classNames: 'span1'

  didInsertElement: ->
    @$().spin('small')

  willDestroyElement: ->
    @$().spin(false)
