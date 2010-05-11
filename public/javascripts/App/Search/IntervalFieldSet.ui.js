App.Search.IntervalFieldSetUi = Ext.extend(Ext.form.FieldSet, {
    title: 'Interval',
    layout: 'form',
    width: 80,
    height: 90,
    labelWidth: 25,
    initComponent: function() {
        this.items = [
            {
                xtype: 'numberfield',
                fieldLabel: 'Min',
                anchor: '100%'
            },
            {
                xtype: 'numberfield',
                fieldLabel: 'Max',
                anchor: '100%'
            }
        ];
        App.Search.IntervalFieldSetUi.superclass.initComponent.call(this);
    }
});
