App.Search.SearchPanelUi = Ext.extend(Ext.TabPanel, {
  title: ' ',
  activeTab: 0,

  initComponent: function() {
    this.items = [
      new App.Search.SearchCriteriaPanel(),
      new App.Search.SearchResultsPanel()
    ];

		// set up references to the subpanels
		this.searchCriteriaPanel = this.items[0];
		this.searchResultsPanel = this.items[1];
		
    App.Search.SearchPanelUi.superclass.initComponent.call(this);
  }
});


