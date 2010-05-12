var globalLanguageBarNo = 0;

App.Search.LanguageBar = Ext.extend(App.Search.LanguageBarUi, {
  initComponent: function() {
    App.Search.LanguageBar.superclass.initComponent.call(this);

    globalLanguageBarNo++;
    this.languageBarNo = globalLanguageBarNo;

    this.buildToolbar();

    this.add({
      xtype: 'querytermfieldset',
      title: 'Word 1'
    });
    this.add({
      xtype: 'intervalfieldset'
    });
    this.add({
      xtype: 'querytermfieldset',
      title: 'Word 2'
    });
  },

  buildToolbar: function() {
    var toolbar = this.getTopToolbar();
    toolbar.addField({
      xtype: 'combo',
      ref: 'languageCombo',
      typeAhead: true,
      triggerAction: 'all',
      lazyRender:true,
      mode: 'local',
      store: new Ext.data.ArrayStore({
        id: 0,
        fields: [
          'myId',
          'displayText'
        ],
        data: [[1, 'Norwegian'], [2, 'English']]
      }),
      valueField: 'myId',
      displayField: 'displayText',
      value: this.languageBarNo
    });
    toolbar.addButton({
      text: 'Delete language',
      cls: 'x-btn-text-icon',
      icon: 'images/delete.png'
    });
  }
});

Ext.reg("languagebar", App.Search.LanguageBar);
