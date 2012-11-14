App.RegexSearchController = Em.Controller.extend

  # This will be bound to the search field by the template
  queryInputValue: ''

  createQuery: ->
    # For regex queries, the query value is simply the contents of the search
    # field
    @get('queryInputValue')