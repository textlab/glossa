var globalLanguageBarNo = 0;

App.Search.LanguageBar = Ext.extend(App.Search.LanguageBarUi, {
  initComponent: function() {
		// keeps track of fieldsets that are needed when building
		// the query spec
		this.fieldSets = new Array();
			
    App.Search.LanguageBar.superclass.initComponent.call(this);

    globalLanguageBarNo++;
    this.languageBarNo = globalLanguageBarNo;

    this.buildToolbar();
    this.setupSubcomponents();
    this.setupEvents();
  },

	// functions to add and remove fieldsets from the fieldSets array
	registerFieldSet: function(fieldSet) {
			this.fieldSets.push(fieldSet);
	},

	deregisterLastFieldSet: function() {
			return this.fieldSets.pop();
	},

	// returns the spec and the language for this LanguageBar as a pair
	// Language is the first element followed by the corpus query spec.
	getQuerySpec: function() {
			var specs = new Array();

			Ext.each(this.fieldSets, function(f, i) { specs.push(f.getQuerySpec()); });

			return [this.getTopToolbar().items.first().getValue(), specs];
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
      valueField: 'displayText',
      displayField: 'displayText'
    });
    toolbar.addButton({
      text: 'Delete language',
      cls: 'x-btn-text-icon',
      icon: 'images/delete.png'
    });
  },

  setupSubcomponents: function() {
    this.nWords = 1;
		var fieldSet = new App.Search.QueryTermFieldSet({ title: 'Word ' + this.nWords });
    this.insert(0, fieldSet);

		// remember to add fields to fieldSets array
		this.registerFieldSet(fieldSet);
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

		// to keep track of fieldsets they have to be instantiated
		// registered in the fieldSets array and inserted into
		// the panel
		var intervalField = new App.Search.IntervalFieldSet();
    this.insert(this.items.getCount() - 1, intervalField);
		this.registerFieldSet(intervalField);

		var termField = new App.Search.QueryTermFieldSet({ title: 'Word ' + this.nWords });
		this.insert(this.items.getCount() - 1, termField);
		this.registerFieldSet(termField);
			
    this.doLayout();
    this.deleteWordButton.enable();
  },

  deleteWord: function() {
    this.nWords--;
    this.remove(this.items.itemAt(this.items.getCount() - 2));
    this.remove(this.items.itemAt(this.items.getCount() - 2));
    this.doLayout();

		// remember to remove fields from fieldSets array
		this.deregisterLastFieldSet();
		this.deregisterLastFieldSet();

    if(this.items.getCount() == 2) {
      this.deleteWordButton.disable();
    }
  }
});

Ext.reg("languagebar", App.Search.LanguageBar);
