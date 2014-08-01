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
    resetSearchForm: ->
      @transitionTo('start')
  substates:
    start: {}
    results: {}

window.App = React.createClass
  getInitialState: ->
    store: new Store(models, plurals, (store) => @setState(store: store))
    statechart: new Statechart('Main', root, (sc) => @setState(statechart: sc))

  preloadImages: ->
    `[<img key="spinner-small" style={{display: 'none'}} src="assets/rglossa/spinner-small.gif" />,
      <img key="spinner-large" style={{display: 'none'}} src="assets/rglossa/spinner-large.gif" />]`

  render: ->
    corpusShortName = location.search.match(/corpus=(.+)/)?[1]
    alert('Please provide a corpus name in the query string') unless corpusShortName

    corpus = @state.store.findBy('corpus', 'short_name', corpusShortName)
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
