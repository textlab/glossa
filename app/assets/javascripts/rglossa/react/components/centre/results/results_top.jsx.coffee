#= require ./num_hits

###* @jsx React.DOM ###

window.ResultsTop = React.createClass
  propTypes:
    corpus: React.PropTypes.object.isRequired
    results: React.PropTypes.object.isRequired
    maxHits: React.PropTypes.number.isRequired
    handleMaxHitsChanged: React.PropTypes.func.isRequired

  render: ->
    {results, corpus, maxHits, handleMaxHitsChanged} = @props
    `<NumHits
      corpus={corpus}
      results={results}
      maxHits={maxHits}
      handleMaxHitsChanged={handleMaxHitsChanged} />`
