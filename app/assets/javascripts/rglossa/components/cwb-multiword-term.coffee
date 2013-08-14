App.CwbMultiwordTermComponent = Em.Component.extend
  classNames: ['table-cell']

  removeTerm: ->
    @get('multiwordController').removeTerm(@get('term'))
