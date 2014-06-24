#= require ./main_area_top
#= require ./main_area_bottom

###* @jsx React.DOM ###

window.MainArea = React.createClass
  propTypes:
    store: React.PropTypes.object.isRequired
    statechart: React.PropTypes.object.isRequired
    corpus: React.PropTypes.object.isRequired

  getInitialState: ->
    query: ''
    maxHits: 2000

  handleQueryChanged: (query) ->
    @setState(query: query)

  handleMaxHitsChanged: (maxHits) ->
    @setState(maxHits: maxHits)
    @handleSearch()

  showCorpusHome: ->
    alert 'showCorpusHome'

  handleSearch: ->
    {store, statechart, corpus} = @props
    searchEngine = corpus.search_engine ?= 'cwb'
    url = "search_engines/#{searchEngine}_searches"
    query =
      query: @state.query
      corpusShortName: corpus.short_name

    $.ajax(
      url: url
      method: 'POST'
      data: JSON.stringify
        queries: [query]
        max_hits: @state.maxHits
      dataType: 'json'
      contentType: 'application/json'
    ).then (res) =>
      searchModel = "#{searchEngine}_search"
      search = res[searchModel]
      search.pages = search.first_two_result_pages

      delete search.pages['2'] if search.pages['2'].length is 0
      delete search.first_two_result_pages
      id = search.id

      store.setData('search', id, search)
      statechart.handleAction('showResults', id)


  render: ->
    {store, statechart, corpus} = @props
    searchId = statechart.getValue('searchId')
    results = if searchId then store.find('search', searchId) else null

    `<span>
      <div className="container-fluid">

        <MainAreaTop
          statechart={statechart}
          corpus={corpus}
          results={results}
          maxHits={this.state.maxHits}
          handleMaxHitsChanged={this.handleMaxHitsChanged} />

        <MainAreaBottom
          store={store}
          statechart={statechart}
          corpus={corpus}
          results={results}
          query={this.state.query}
          handleQueryChanged={this.handleQueryChanged}
          maxHits={this.state.maxHits}
          handleSearch={this.handleSearch} />
      </div>
    </span>`
