App.CorpusView = Em.View.extend

  # If the width of the browser window is <= this, we automatically hide the sidebar
  # to make more room for search results.
  maxAutoHideSidebarWidth: 1100
  hideSidebarSelector: null

  didInsertElement: ->
    @determineHideSidebarSelector()
    @$().on('click', @hideSidebarSelector, @hideSidebar)
    @$().on 'keyup', (e) =>
      @hideSidebar() if e.keyCode is 13 and $('body').width() <= @maxAutoHideSidebarWidth

    if @get('controller.metadataCategories.length')
      @$().on('click', '#show-criteria-button, #new-search-button', @showSidebar)

    $(window).resize =>
      @$().off('click', @hideSidebarSelector, @hideSidebar)
      @determineHideSidebarSelector()
      @$().on('click', @hideSidebarSelector, @hideSidebar)

  willDestroyElement: ->
    @$().off('click', @hideSidebarSelector, @hideSidebar)
    @$().off 'keyup'

    if @get('controller.metadataCategories.length')
      @$().off('click', '#show-criteria-button, #new-search-button', @showSidebar)


  determineHideSidebarSelector: ->
    if $('body').width() <= @maxAutoHideSidebarWidth
      # automatically hide sidebar when searching if the browser window is narrow
      @hideSidebarSelector = '#hide-criteria-button, button[data-search]'
    else
      @hideSidebarSelector = '#hide-criteria-button'


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
