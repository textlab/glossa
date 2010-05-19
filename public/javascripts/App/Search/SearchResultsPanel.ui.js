App.Search.SearchResultsPanelUi = Ext.extend(Ext.grid.GridPanel, {
  title: 'Search results',
  columns: [{header: 'Result'}],
  store: {xtype: 'arraystore'},
  bbar: {
    xtype: 'paging'
  },

  initComponent: function() {
    App.Search.SearchResultsPanelUi.superclass.initComponent.call(this);
  }
});

