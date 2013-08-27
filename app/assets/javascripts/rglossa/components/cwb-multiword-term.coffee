App.CwbMultiwordTermComponent = Em.Component.extend
  classNames: ['table-cell']

  didInsertElement: ->
    @get('tagsInput').addTag(term.value) for term in @get('term.features')

  tagsInput: (->
    unless @_tagsInput
      @_tagsInput = @$('[data-term-tags]').tags(
        promptText: ' '
      )
      pos = @get('term.pos.name')
      @_tagsInput.addTag(pos) if pos

    @_tagsInput
  ).property()

  addTerm: ->
    @get('parentView').addTerm()

  removeTerm: ->
    @get('parentView').removeTerm(@get('term'))

  addPos: (pos) ->
    @set('term.pos', pos)
    @get('tagsInput').addTag(pos.name)

  addFeature: (option, feature, pos) ->
    @get('term.features').pushObject
      attr: feature.attr
      value: option.value

    @get('tagsInput').addTag(option.value)

    # TODO: Figure out why observing the features array doesn't work so that we
    # have to do this manually
    @get('parentView').displayedQueryDidChange()
