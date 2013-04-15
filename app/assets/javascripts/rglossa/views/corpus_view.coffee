App.CorpusView = Em.View.extend

  didInsertElement: ->
    @$().on('click', '#hide-criteria-button, button[data-search]', @hideSidebar)
    @$().on('click', '#show-criteria-button', @showSidebar)


  willRemoveElement: ->
    @$().off('click', '#hide-criteria-button, button[data-search]', @hideSidebar)
    @$().off('click', '#show-criteria-button', @showSidebar)


  hideSidebar: ->
    $('#hide-criteria-button').hide()

    $('#left-sidebar').animate {width: 'hide'}, 100, ->
        $('#main-content').removeClass('span9').addClass('span12 no-sidebar')

    $('#show-criteria-button').show()

  showSidebar: ->
    $('#show-criteria-button').hide()

    $('#main-content').removeClass('span12 no-sidebar').addClass('span9')
    $('#left-sidebar').animate {width: 'show'}, 100

    $('#hide-criteria-button').show()
