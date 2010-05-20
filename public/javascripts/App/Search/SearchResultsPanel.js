App.Search.SearchResultsPanel = Ext.extend(App.Search.SearchResultsPanelUi, {
  initComponent: function() {
    App.Search.SearchResultsPanel.superclass.initComponent.call(this);

		App.Controller.resultGrid = this;
  }
});


