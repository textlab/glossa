App.CwbMultiwordView = Em.View.extend
  templateName: 'cwb/multiword'

  didInsertElement: ->
    @$('.searchfield').first().focus()
