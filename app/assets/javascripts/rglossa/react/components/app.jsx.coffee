#= require ../store
#= require ../statechart
#= require ./top/navbar
#= require ./centre/main_area

###* @jsx React.DOM ###

models = [
  'corpora'
]

states =
  start: {}
  results: {}

window.App = React.createClass
  getInitialState: ->
    store: new Store(models, (store) => @setState(store: store))
    statechart: new Statechart('Main', states, 'start', (sc) => @setState(statechart: sc))

  render: ->
    `<span>
      <Navbar />
      <MainArea statechart={this.state.statechart} />
    </span>`
