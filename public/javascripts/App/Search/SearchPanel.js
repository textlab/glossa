App.Search.SearchPanel = Ext.extend(App.Search.SearchPanelUi, {
  initComponent: function() {
    App.Search.SearchPanel.superclass.initComponent.call(this);

    this.add({
      xtype: 'languagebar'
    }, {
      xtype: 'languagebar'
    });
  }
});
Ext.reg("searchpanel", App.Search.SearchPanel);

