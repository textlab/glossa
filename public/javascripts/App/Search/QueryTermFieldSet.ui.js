App.Search.QueryTermFieldSetUi = Ext.extend(Ext.form.FieldSet, {
    layout: 'vbox',
    width: 200,
    autoHeight: false,
    height: 90,
    disabled: false,
    defaultType: '',
    initComponent: function() {
        this.defaults = {
            margins: '5 0 5 0'
        };
        this.layoutConfig = {
            align: 'stretch',
            pack: 'start'
        };
        this.items = [
            {
                xtype: 'textfield',
                fieldLabel: 'Label',
                hideLabel: true,
                style: '',
                margins: ''
            },
            {
                xtype: 'container',
                autoEl: 'div',
                layout: 'hbox',
                autoWidth: false,
                layoutConfig: {
                    align: 'top',
                    pack: 'start'
                },
                items: [
                    {
                        xtype: 'button',
                        text: 'Options'
                    },
                    {
                        xtype: 'container',
                        autoEl: 'div',
                        flex: 1,
                        layout: 'vbox'
                    }
                ]
            }
        ];
        App.Search.QueryTermFieldSetUi.superclass.initComponent.call(this);
    }
});
