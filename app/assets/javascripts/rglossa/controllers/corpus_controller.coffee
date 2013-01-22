App.CorpusController = Em.ObjectController.extend
  # Need to initialize `content` to an empty object to allow bindings to be
  # set up before `content` is set to an actual corpus model (otherwise, the
  # bindings initialization code will throw an exception)
  content: {}

  needs: 'currentUser'

  # Reopen the class and change this if you want a different default search
  # engine
  defaultSearchEngine: 'cwb'

  # Reopen the class and add to this object if you implement other search
  # engines
  defaultSearchInterfaceVariant:
    cwb: 'regex'

  userPreferencesBinding: 'controllers.currentUser.preferences'


  # The search engine for the current corpus
  searchEngine: (->
    @get('model.searchEngine') or @defaultSearchEngine
  ).property('model.searchEngine')


  # The Handlebars template for the interface of the current search engine
  searchInterfaceTemplate: (->
    engine = @get('searchEngine')
    "search/#{engine}"
  ).property('searchEngine')


  # Returns e.g. "simple", "multiword" or "regex" for the CWB search engine,
  # depending on the user's preferences or the default variant
  preferredSearchInterfaceVariant: (->
    engine  = @get('searchEngine')
    variant = @get('userPreferences.interfaces')?[engine] or
      @defaultSearchInterfaceVariant[engine]
  ).property('searchEngine', 'userPreferences.interfaces')


  resultPageController: (->
    engine = @get('searchEngine')

    "#{engine}ResultPageController"
  ).property('searchEngine')