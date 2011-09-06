App.Search.SearchResultsPanelUi = Ext.extend(Ext.grid.GridPanel, {
  title: 'Search results',
  columns: [{
    id: 'line',
    xtype: 'templatecolumn',
    header: 'Result',
    dataIndex: 'line',
    tpl: new Ext.XTemplate('<tpl for="line">{.}<br></tpl>')
  }],
  autoExpandColumn: 'line',
  bbar: {
    xtype: 'paging'
  },
  ref: 'searchResultsPanel',
  disabled: true,

  initComponent: function() {
    // Remember to create a new store for each results panel
    var store = new Ext.data.JsonStore({
      autoDestroy: true,
      fields: ['line'],
      url: urlRoot + 'searches/query',
      totalProperty: 'querySize',
      root: 'data'
    });
    this.store = store;

    App.Search.SearchResultsPanelUi.superclass.initComponent.call(this);

    // connect pager to the grids datastore
    // bindStore() undocumented ? - Anders: No, it is documented in the API documentation
    this.getBottomToolbar().bindStore(store);
    this.getBottomToolbar().pageSize = App.Controller.resultPagerSize;
  }
});
