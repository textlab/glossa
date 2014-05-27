#= require ../store
#= require ../statechart
#= require ./top/navbar
#= require ./centre/main_area

###* @jsx React.DOM ###

models = [
  'corpora'
]

plurals =
  corpus: 'corpora'

root =
  initialSubstate: 'start'
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
          statechart={this.state.statechart}
          corpus={corpus} />
        : null}
    </span>`
