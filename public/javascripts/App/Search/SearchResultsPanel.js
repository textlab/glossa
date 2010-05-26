App.Search.SearchResultsPanel = Ext.extend(App.Search.SearchResultsPanelUi, {
  initComponent: function() {
		var queryId = '0';

		// store references to the grid in the store and the proxy so that they
		// can update the queryId in their event handlers
		this.store.searchResultPanel = this;
		this.store.proxy.searchResultPanel = this;
		
    App.Search.SearchResultsPanel.superclass.initComponent.call(this);

		App.Controller.resultGrid = this;

		this.store.proxy.on('beforeload', function(proxy, params) {
			// insert the query id before calling the server
			// changes between the initial request and further
			// paging so it must be reevaluated on each call
			params.queryId = this.searchResultPanel.queryId;

			return true;
		});

		this.store.on('load', function(records, options) {
			// save the returned query id for use in fex. paging
			this.searchResultPanel.queryId = this.reader.jsonData.queryId;

			return true;
		});
  }
});


