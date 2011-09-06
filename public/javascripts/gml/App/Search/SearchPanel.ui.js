App.Search.SearchPanelUi = Ext.extend(Ext.TabPanel, {
  title: ' ',
  activeTab: 0,

  initComponent: function() {
    this.items = [
      new App.Search.SearchCriteriaPanel(),
      new App.Search.SearchResultsPanel()
    ];

    App.Search.SearchPanelUi.superclass.initComponent.call(this);
  }
});


