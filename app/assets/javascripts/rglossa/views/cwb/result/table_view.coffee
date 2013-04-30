App.CwbResultTableView = Em.View.extend

  didInsertElement: ->
    @$('[data-ot]').each (index, token) ->
      new Opentip token, $(token).data('ot'),
        style: 'dark'
        fixed: true
