###* @jsx React.DOM ###

window.MainArea = React.createClass
  sideBarButtons: ->
    `<button id="hide-criteria-button" className="btn btn-mini" title="Hide search criteria">
      <i className="icon-double-angle-left"> Hide</i>
    </button>
    <button id="show-criteria-button" className="btn btn-mini" style={{display: 'none'}} title="Show search criteria">
      <i className="icon-double-angle-right" /> Filters
    </button>`


  rowWithSidebar: ->
    `<div id="left-sidebar" className="span3">
      {{render "corpus/metadata_categories" metadataCategories}}
    </div>
    <div id="main-content" className="span9">
      OUTLET
    </div>`


  rowWithoutSidebar: ->
    `<div id="main-content" className="span12">
      OUTLET
    </div>`


  showCorpusHome: ->
    alert 'showCorpusHome'


  render: ->
    `<span>
      <div className="container-fluid">
        <div className="row-fluid">
          <div className="span3 top-toolbar">
            {false ? this.sideBarButtons() : ''}
            <button onClick="this.showCorpusHome" id="new-search-button" className="btn btn-mini btn-primary" style={{display: 'none'}} title="Reset form">
              Reset form
            </button>
          </div>
          <div className="span9">
            OUTLET NUMHITS
          </div>
        </div>
        <div className="row-fluid">
          {false ? this.rowWithSidebar() : this.rowWithoutSidebar()}
        </div>
      </div>
    </span>`
