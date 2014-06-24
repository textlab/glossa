#= require ./num_hits

###* @jsx React.DOM ###

window.ResultsTop = React.createClass
  propTypes:
    results: React.PropTypes.object.isRequired
    corpus: React.PropTypes.object.isRequired
    maxHits: React.PropTypes.number.isRequired
    handleMaxHitsChanged: React.PropTypes.func.isRequired

  render: ->
    {results, corpus, maxHits, handleMaxHitsChanged} = @props
    `<NumHits
      results={results}
      corpus={corpus}
      maxHits={maxHits}
      handleMaxHitsChanged={handleMaxHitsChanged} />`
