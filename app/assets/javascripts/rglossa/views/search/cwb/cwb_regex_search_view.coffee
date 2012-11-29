App.CwbRegexSearchView = Em.View.extend
  templateName: 'search/cwb/cwb_regex_search'

  didInsertElement: ->
    @$('.searchfield').focus()