App.Search.QueryTermFieldSet = Ext.extend(App.Search.QueryTermFieldSetUi, {
    initComponent: function() {
        App.Search.QueryTermFieldSet.superclass.initComponent.call(this);

        this.add({
          xtype: 'intervalfieldset'
        });
    }
});
Ext.reg("querytermfieldset", App.Search.QueryTermFieldSet);
