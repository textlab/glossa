#= require rglossa/react/utils

###* @jsx React.DOM ###

window.NumHits = React.createClass
  propTypes:
    corpus: React.PropTypes.object.isRequired
    results: React.PropTypes.object.isRequired
    maxHits: React.PropTypes.number.isRequired
    handleMaxHitsChanged: React.PropTypes.func.isRequired

  getInitialState: ->
    displayedMaxHits: @props.results.num_hits # see comments in handleMaxHitsChanged below

  componentWillReceiveProps: (nextProps) ->
    if nextProps.results.num_hits isnt @state.displayedMaxHits
      # see comments in handleMaxHitsChanged below for why we need displayedMaxHits
      @setState(displayedMaxHits: nextProps.results.num_hits)

  handleMaxHitsChanged: (e) ->
    maxHits = parseInt(e.target.value)
    unless isNaN(maxHits)
      # Set displayedMaxHits right away so that the text box shows the updated number...
      @setState(displayedMaxHits: e.target.value)
      # ...but debounce the new search in order to give the user time to finish writing
      # the new page number
      @debouncedHandleMaxHitsChanged(maxHits) if maxHits > 0

  debouncedHandleMaxHitsChanged: debounce ((maxHits) -> @props.handleMaxHitsChanged(maxHits)), 500

  render: ->
    {corpus, results, maxHits} = @props
    hitsAreCutOff = results.num_hits is maxHits
    noResultsFound = results.num_hits is 0
    hasReceivedResults = typeof(results.num_hits) isnt 'undefined'
    parts = corpus.parts or []

    `<div>
      {hitsAreCutOff
        ? <span>Showing the first <input type="text" className="span1 max-hits"
            value={this.state.displayedMaxHits}
            onChange={this.handleMaxHitsChanged} /> matches  
            <button className="btn btn-small" AAaction="" showallhitsBB="">Show all</button></span>
        : noResultsFound
          ? <span>No matches found</span>
          : hasReceivedResults
            ? <span>Found {results.num_hits} matches</span>
            : <div className="row-fluid">
                AAview App.HitCounterSpinnerViewBB <div className="counting-matches">Counting matches...</div>
              </div>}

      {parts.map(function(part) {
        <span className="corpus-part-name">{part.short_name} = {part.name}</span>
      })}
    </div>`
