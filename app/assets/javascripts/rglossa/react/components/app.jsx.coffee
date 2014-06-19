#= require ../store
#= require ../statechart
#= require ./top/navbar
#= require ./centre/main_area

###* @jsx React.DOM ###

models = [
  'corpora'
  'searches'
  'results'
]

plurals =
  corpus: 'corpora'
  search: 'searches'

root =
  initialSubstate: 'start'
  actions:
    setQuery: (query) ->
      @transitionTo('.', query: query) # don't really transition, just set query arg
    showResults: (searchId, pageNo = 1) ->
      @transitionTo('results',
        searchId: searchId
        currentResultPageNo: pageNo)
  substates:
    start: {}
    results: {}

window.App = React.createClass
  getInitialState: ->
    store: new Store(models, plurals, (store) => @setState(store: store))
    statechart: new Statechart('Main', root, (sc) => @setState(statechart: sc))

  render: ->
    corpus = @state.store.find('corpus', 2)
    `<span>
      <Navbar />
      {corpus
        ? <MainArea
          store={this.state.store}
          statechart={this.state.statechart}
          corpus={corpus} />
        : null}
    </span>`
