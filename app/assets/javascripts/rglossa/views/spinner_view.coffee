App.SpinnerView = Em.View.extend
  templateName: 'spinner'

  didInsertElement: ->
    $('.spinner').spin()

  willDestroyElement: ->
    $('.spinner').spin(false)