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
  defaultSearchInterface:
    cwb: 'regex'

  userPreferencesBinding: 'controllers.currentUser.preferences'


  # The search engine for the current corpus
  searchEngine: (->
    @get('model.searchEngine') or @defaultSearchEngine
  ).property('model.searchEngine')


  # The interface that matches the user's preferences for the search engine
  # for the current corpus (e.g. simple, multiword or regex for CWB corpora).
  # The search engine is determined by the corpus itself or set to a default,
  # while the interface type is taken from the user's preferences or a default
  # for the search engine.
  searchInterface: (->
    engine = @get('searchEngine')
    interf = @get('userPreferences.interfaces')?[engine] or
      @defaultSearchInterface[engine]

    "#{engine}#{interf.classify()}"
  ).property('searchEngine', 'userPreferences.interfaces')


  resultPageController: (->
    engine = @get('searchEngine')

    "#{engine}ResultPageController"
  ).property('searchEngine')