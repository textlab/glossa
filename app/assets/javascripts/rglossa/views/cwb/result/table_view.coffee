App.CwbResultTableView = Em.View.extend

  contentBinding: 'controller.arrangedContent'

  # We need to create tooltips with grammatical info for tokens after both of these have happened:
  # - the controller's content property has been filled with a page of search results
  # - the view has been rendered
  contentDidChange: (->
    return unless @get('content.length')

    # Use the afterRender queue since the table rows may not be rendered yet even though the
    # content property has been filled.
    Ember.run.scheduleOnce 'afterRender', @, ->
      @$('[data-ot]').each (index, token) ->
        new Opentip token, $(token).data('ot'),
          style: 'dark'
          fixed: true
  ).observes('content.length')
