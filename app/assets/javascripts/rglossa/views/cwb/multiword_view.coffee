App.CwbMultiwordView = Em.View.extend
  templateName: 'cwb/multiword'

  didInsertElement: ->
    @$('.searchfield').first().focus()

  focusOut: ->
    @get('controller').updateQuery()
