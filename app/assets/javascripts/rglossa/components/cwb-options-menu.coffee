App.CwbOptionsMenuComponent = Em.Component.extend
  tagName: 'ul'
  classNames: 'dropdown-menu'

  addPos: (pos) -> @get('parentView').addPos(pos)

  addFeature: (feature, pos) ->
    @get('parentView').addFeature(feature, pos)
