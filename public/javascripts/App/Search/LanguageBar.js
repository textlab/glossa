var globalLanguageBarNo = 0;

App.Search.LanguageBar = Ext.extend(App.Search.LanguageBarUi, {
  initComponent: function() {
    App.Search.LanguageBar.superclass.initComponent.call(this);

    globalLanguageBarNo++;
    this.languageBarNo = globalLanguageBarNo;

    this.buildToolbar();
    this.setupSubcomponents();
    this.setupEvents();
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
  },

  setupSubcomponents: function() {
    this.nWords = 1;
    this.insert(0, {
      xtype: 'querytermfieldset',
      title: 'Word ' + this.nWords
    });
  },

  setupEvents: function() {
    this.addWordButton.on('click', function() {
      this.addWord();
    }, this);
    this.deleteWordButton.on('click', function() {
      this.deleteWord();
    }, this);
  },

  addWord: function() {
    this.nWords++;
    this.insert(this.items.getCount() - 1, {
      xtype: 'intervalfieldset'
    });
    this.insert(this.items.getCount() - 1, {
      xtype: 'querytermfieldset',
      title: 'Word ' + this.nWords
    });
    this.doLayout();
    this.deleteWordButton.enable();
  },

  deleteWord: function() {
    this.nWords--;
    this.remove(this.items.itemAt(this.items.getCount() - 2));
    this.remove(this.items.itemAt(this.items.getCount() - 2));
    this.doLayout();

    if(this.items.getCount() == 2) {
      this.deleteWordButton.disable();
    }
  }
});

Ext.reg("languagebar", App.Search.LanguageBar);
