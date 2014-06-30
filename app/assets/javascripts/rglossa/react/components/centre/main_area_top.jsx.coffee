#= require ./results/results_top

###* @jsx React.DOM ###

window.MainAreaTop = React.createClass
  propTypes:
    statechart: React.PropTypes.object.isRequired
    corpus: React.PropTypes.object.isRequired
    results: React.PropTypes.object
    maxHits: React.PropTypes.number
    handleMaxHitsChanged: React.PropTypes.func.isRequired

  sideBarButtons: ->
    `<span>
      <button id="hide-criteria-button" className="btn btn-mini" title="Hide search criteria">
        <i className="icon-double-angle-left"> Hide</i>
      </button>
      <button id="show-criteria-button" className="btn btn-mini" style={{display: 'none'}} title="Show search criteria">
        <i className="icon-double-angle-right" /> Filters
      </button>
    </span>`


  render: ->
    {statechart, corpus, results, maxHits, handleMaxHitsChanged} = @props
    `<div className="row-fluid">
      <div className="span3 top-toolbar">
        {true ? this.sideBarButtons() : null}
        <button onClick={this.showCorpusHome} id="new-search-button" className="btn btn-mini btn-primary" title="Reset form">
          Reset form
        </button>
      </div>
      <div className="span9">
        {statechart.pathContains('start')
          ? null
          : <ResultsTop
              corpus={corpus}
              results={results}
              maxHits={maxHits}
              handleMaxHitsChanged={handleMaxHitsChanged} />}
      </div>
      </div>`
