App.CorpusView = Em.View.extend

  didInsertElement: ->
    @$().on('click', '[data-search-button]', @collapseSidebar)

  willRemoveElement: ->
    @$().off('click', '[data-search-button]', @collapseSidebar)

  collapseSidebar: ->
    $('#left-sidebar')
      .animate {width: 'toggle'}, 100, ->
        $('#main-content').toggleClass('span12 span9 no-sidebar')