#= require ./results/results_top

###* @jsx React.DOM ###

window.MainAreaTop = React.createClass
  propTypes:
    statechart: React.PropTypes.object.isRequired

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
    `<div className="row-fluid">
      <div className="span3 top-toolbar">
        {true ? this.sideBarButtons() : ''}
        <button onClick={this.showCorpusHome} id="new-search-button" className="btn btn-mini btn-primary" title="Reset form">
          Reset form
        </button>
      </div>
      <div className="span9">
        {this.props.statechart.pathContains('start') ? '' : <ResultsTop />}
      </div>
      </div>`