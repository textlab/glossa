App.CorpusController = Em.ObjectController.extend

  needs: 'currentUser'

  # Reopen the class and change this if you want a different default search
  # engine
  defaultSearchEngine: 'cwb'

  # Reopen the class and add to this object if you implement other search
  # engines
  defaultSearchInterfaceVariant:
    cwb: 'regex'

  userPreferences: null
  userPreferencesBinding: 'controllers.currentUser.preferences'


  # The search engine for the current corpus
  searchEngine: (->
    @get('model.searchEngine') or @defaultSearchEngine
  ).property('model.searchEngine')


  # The search model subclass for the current search engine
  searchModelClass: (->
    engine = @get('searchEngine')
    App.get("#{engine.classify()}Search")
  ).property('searchEngine')


  # The Handlebars template for the interface of the current search engine
  searchInterfaceTemplate: (->
    engine = @get('searchEngine')
    "home/#{engine}"
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