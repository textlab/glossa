App.SearchController = Em.ObjectController.extend
  # NOTE: search input controllers for each individual search engine need to be
  # listed here because Ember won't let us look up controllers dynamically
  needs: ['searches', 'cwbSearchInputs']

  content: null
  contentBinding: 'controllers.searches.currentSearch'

  hitsAreCutOff: (->
    @get('content.numHits') is @get('content.maxHits')
  ).property('content.numHits', 'content.maxHits')

  setMaxHits: (value) ->
    searchType = @get('content').constructor.toString().split('.')[1] # e.g. "CwbSearch"
    controller = searchType.camelize() + 'Inputs' # e.g. "cwbSearchInputs"
    @get("controllers.#{controller}").search({maxHits: value})
