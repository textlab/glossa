#= require ./main_area_top
#= require ./main_area_bottom

###* @jsx React.DOM ###

window.MainArea = React.createClass
  propTypes:
    store: React.PropTypes.object.isRequired
    statechart: React.PropTypes.object.isRequired
    corpus: React.PropTypes.object.isRequired

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
          corpus={corpus} />

        <MainAreaBottom
          store={store}
          statechart={statechart}
          results={results}
          corpus={corpus} />
      </div>
    </span>`
