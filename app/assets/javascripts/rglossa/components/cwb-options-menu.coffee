App.CwbOptionsMenuComponent = Em.Component.extend
  tagName: 'ul'
  classNames: 'dropdown-menu'

  init: -> 
    @_super()
    console.log @get('tags')


