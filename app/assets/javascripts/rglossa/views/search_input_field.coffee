App.SearchInputField = Em.TextField.extend

  insertNewline: ->
    @get('controller').search()