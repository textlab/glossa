App.Search.SearchResultsPanelUi = Ext.extend(Ext.grid.GridPanel, {
  title: 'Search results',
  columns: [{header: 'Result', dataIndex: 'line'}],
  store: new Ext.data.JsonStore({
		fields: ['line'],
 		url: urlRoot + 'searches/query',
		totalProperty: 'querySize',
		root: 'data',
		id: 'resultStore'
	}),
  bbar: {
    xtype: 'paging'
  },

  initComponent: function() {
    App.Search.SearchResultsPanelUi.superclass.initComponent.call(this);
  }
});

