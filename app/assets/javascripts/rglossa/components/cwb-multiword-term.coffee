App.CwbMultiwordTermComponent = Em.Component.extend
  classNames: ['table-cell']

  addTerm: ->
    @get('parentView').addTerm()

  removeTerm: ->
    @get('parentView').removeTerm(@get('term'))
