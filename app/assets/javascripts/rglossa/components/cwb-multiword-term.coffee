App.CwbMultiwordTermComponent = Em.Component.extend
  classNames: ['table-cell']

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

  addFeature: (feature, pos) ->
    @get('term.features').pushObject(feature.value)
    @get('tagsInput').addTag(feature.name)
