###* @jsx React.DOM ###

window.NumHits = React.createClass
  propTypes:
    results: React.PropTypes.object.isRequired
    corpus: React.PropTypes.object.isRequired

  render: ->
    {results, corpus} = @props
    hitsAreCutOff = results.num_hits is results.max_hits
    noResultsFound = results.num_hits is 0
    hasHits = !!results.num_hits
    parts = corpus.parts or []

    `<div>
      {hitsAreCutOff
        ? <span>Showing the first <input type="text" className="span1 max-hits" value={results.num_hits} /> matches  
            <button className="btn btn-small" AAaction="" showallhitsBB="">Show all</button></span>
        : noResultsFound
          ? <span>No matches found</span>
          : hasHits
            ? <span>Found {results.num_hits} matches</span>
            : <div className="row-fluid">
                AAview App.HitCounterSpinnerViewBB <div className="counting-matches">Counting matches...</div>
              </div>}

      {parts.map(function(part) {
        <span className="corpus-part-name">{part.short_name} = {part.name}</span>
      })}
    </div>`
