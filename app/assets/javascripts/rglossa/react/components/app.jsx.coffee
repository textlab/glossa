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

  preloadImages: ->
    `[<img style={{display: 'none'}} src="assets/rglossa/spinner-small.gif" />,
      <img style={{display: 'none'}} src="assets/rglossa/spinner-large.gif" />]`

  render: ->
    corpus = @state.store.find('corpus', 2)
    `<span>
      {this.preloadImages()}
      <Navbar />
      {corpus
        ? <MainArea
          store={this.state.store}
          statechart={this.state.statechart}
          corpus={corpus} />
        : null}
    </span>`
