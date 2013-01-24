App.CwbSimpleSearchView = Em.View.extend
  templateName: 'home/cwb/cwb_simple_search'

  didInsertElement: ->
    @$('.searchfield').focus()