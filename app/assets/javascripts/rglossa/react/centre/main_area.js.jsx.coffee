###* @jsx React.DOM ###

window.MainArea = React.createClass
  sideBarButtons: ->
    `<span>
      <button id="hide-criteria-button" className="btn btn-mini" title="Hide search criteria">
        <i className="icon-double-angle-left"> Hide</i>
      </button>
      <button id="show-criteria-button" className="btn btn-mini" style={{display: 'none'}} title="Show search criteria">
        <i className="icon-double-angle-right" /> Filters
      </button>
    </span>`


  rowWithSidebar: ->
    `<span>
      <div id="left-sidebar" className="span3">
        METADATA_CATEGORIES
      </div>
      <div id="main-content" className="span9">
        MAIN_AREA
      </div>
    </span>`


  rowWithoutSidebar: ->
    `<div id="main-content" className="span12">
      MAIN_AREA
    </div>`


  showCorpusHome: ->
    alert 'showCorpusHome'


  render: ->
    `<span>
      <div className="container-fluid">
        <div className="row-fluid">
          <div className="span3 top-toolbar">
            {true ? this.sideBarButtons() : ''}
            <button onClick={this.showCorpusHome} id="new-search-button" className="btn btn-mini btn-primary" title="Reset form">
              Reset form
            </button>
          </div>
          <div className="span9">
            NUMHITS
          </div>
        </div>
        <div className="row-fluid">
          {true ? this.rowWithSidebar() : this.rowWithoutSidebar()}
        </div>
      </div>
    </span>`