#= require rglossa/utils

###* @jsx React.DOM ###

window.NumHits = React.createClass
  propTypes:
    corpus: React.PropTypes.object.isRequired
    results: React.PropTypes.object
    maxHits: React.PropTypes.number
    handleMaxHitsChanged: React.PropTypes.func.isRequired

  getInitialState: ->
    displayedMaxHits: @props.results?.num_hits # see comments in handleMaxHitsChanged below

  componentWillReceiveProps: (nextProps) ->
    num_hits = nextProps.results?.num_hits ? null
    if num_hits isnt @state.displayedMaxHits
      # see comments in handleMaxHitsChanged below for why we need displayedMaxHits
      @setState(displayedMaxHits: num_hits)

  handleMaxHitsChanged: (e) ->
    maxHits = parseInt(e.target.value)
    unless isNaN(maxHits)
      # Set displayedMaxHits right away so that the text box shows the updated number...
      @setState(displayedMaxHits: e.target.value)
      # ...but debounce the new search in order to give the user time to finish writing
      # the new page number
      @debouncedHandleMaxHitsChanged(maxHits) if maxHits > 0

  debouncedHandleMaxHitsChanged: rglossaUtils.debounce ((maxHits) -> @props.handleMaxHitsChanged(maxHits)), 500

  handleShowAll: ->
    @props.handleMaxHitsChanged(null)

  numHitsInfo: ->
    results = @props.results
    noResultsFound = results.num_hits is 0
    hasReceivedTotal = results.total?

    if noResultsFound
      `<span>No matches found</span>`
    else
      if hasReceivedTotal
        `<span>Found {results.total} {results.num_hits === 1 ? 'match' : 'matches'}</span>`
      else
        `<span><div className="spinner-counting-matches" />Counting matches</span>`


  render: ->
    {corpus, results, maxHits} = @props

    if results
      parts = corpus.parts or []
      hitsAreCutOff = results.num_hits is maxHits

      `<div>
        {this.numHitsInfo()}
        {hitsAreCutOff
          ? <span>; showing the first <input type="text" className="span1 max-hits"
              value={this.state.displayedMaxHits}
              onChange={this.handleMaxHitsChanged} />
              <button style={{marginLeft: 10, marginBottom: 3}} className="btn btn-small" onClick={this.handleShowAll}>Show all</button>
            </span>
          : null
        }
        {parts.map(function(part) {
          <span key={part.short_name} className="corpus-part-name">{part.short_name} = {part.name}</span>
        })}
      </div>`
    else
      `<div><div className="spinner-searching-small" />Searching...</div>`

