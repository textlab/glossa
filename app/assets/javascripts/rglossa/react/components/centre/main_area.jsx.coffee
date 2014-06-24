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

  showCorpusHome: ->
    alert 'showCorpusHome'

  render: ->
    {store, statechart, corpus} = @props
    searchId = statechart.getValue('searchId')
    results = if searchId then store.find('search', searchId) else null

    `<span>
      <div className="container-fluid">

        <MainAreaTop
          statechart={statechart}
          results={results}
          corpus={corpus}
          query={this.state.query}
          handleQueryChanged={this.handleQueryChanged}
          maxHits={this.state.maxHits}
          handleMaxHitsChanged={this.handleMaxHitsChanged} />

        <MainAreaBottom
          store={store}
          statechart={statechart}
          corpus={corpus}
          results={results}
          query={this.state.query}
          handleQueryChanged={this.handleQueryChanged}
          maxHits={this.state.maxHits} />
      </div>
    </span>`
