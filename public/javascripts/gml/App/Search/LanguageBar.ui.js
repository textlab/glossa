App.Search.LanguageBarUi = Ext.extend(Ext.Panel, {
    height: 140,
    layout: 'hbox',
    layoutConfig: {
      align: 'middle'
    },
    padding: '10px',
    autoHeight: false,
    tbar: [],
    initComponent: function() {
        this.items = [
            {
                xtype: 'container',
                autoEl: 'div',
                flex: 1,
                style: 'margin-left: 10px',
                defaults: {
                  xtype: 'button',
                  cls: 'x-btn-text-icon',
                  width: 95
                },
                items: [
                    {
                        text: 'Add word&nbsp&nbsp;&nbsp;&nbsp;',
                        icon: urlRoot + 'images/add.png',
                        ref: '../addWordButton',
                        style: 'margin-bottom: 5px'
                    },
                    {
                        text: 'Delete word',
                        icon: urlRoot + 'images/delete.png',
                        ref: '../deleteWordButton',
                        disabled: true
                    }
                ]
            }
        ];
        App.Search.LanguageBarUi.superclass.initComponent.call(this);
    }
});
