App.Search.SearchResultsPanelUi = Ext.extend(Ext.grid.GridPanel, {
  title: 'Search results',
  columns: [{header: 'Result', dataIndex: 'line'}],
	store: new Ext.data.JsonStore({
		fields: ['line'],
 		url: urlRoot + 'searches/query',
		totalProperty: 'querySize',
		root: 'data'
	}),
	bbar: {
    xtype: 'paging'
  },


  initComponent: function() {
    App.Search.SearchResultsPanelUi.superclass.initComponent.call(this);

		// connect pager to the grids datastore
		// bindStore() undocumented ?
		this.getBottomToolbar().bindStore(this.getStore());
  }
});

