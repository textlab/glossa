App.CwbMultiwordTermController = Em.ObjectController.extend

  needs: ['cwbMultiword']

  removeTerm: ->
    @get('controllers.cwbMultiword').removeTerm(@get('content'))
