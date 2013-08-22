App.CwbOptionsMenuComponent = Em.Component.extend
  tagName: 'ul'
  classNames: 'dropdown-menu'

  addPos: (pos) -> @get('parentView').addPos(pos)

  addFeature: (option, feature, pos) ->
    @get('parentView').addFeature(option, feature, pos)
