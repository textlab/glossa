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
    corpora = @state.store.models.corpora
    `<span>
      <Navbar />
      {corpora.length
        ? <MainArea
          statechart={this.state.statechart}
          corpus={corpora[0]} />
        : ''}
    </span>`
