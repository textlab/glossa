App.Search.SearchCriteriaPanel = Ext.extend(App.Search.SearchCriteriaPanelUi, {
  initComponent: function() {
		// keeps track of gui language bars for query building
		this.languageBars = [];

    App.Search.SearchCriteriaPanel.superclass.initComponent.call(this);
    this.setupSubcomponents();
  },

  /* Setup */

  setupSubcomponents: function() {
    this.add(this.createLanguageBar());

    this.addLanguageButton.on('click', this.onAddLanguageClicked, this);
    this.searchButton.on('click', this.onSearchClicked, this);
  },

	// creates and register a LanguageBar gui component
	createLanguageBar: function() {
			bar = new App.Search.LanguageBar();
			this.registerLanguageBar(bar);
			return bar;
	},

	// must be called when adding a language bar to the gui
	registerLanguageBar: function(bar) {
			this.languageBars.push(bar);
	},

	deregisterLanguageBar: function(bar) {
			this.languageBars.remove(bar);
	},

	// returns an object/hash that specifies the query constructed
	// in this SearchCriteriaPanel
	getQuerySpec: function() {
			var specs = {};

			Ext.each(this.languageBars, function(f, i) {
					// get language and spec for this bar and put them in
					// the object using the language as the key
					var langAndSpec = f.getQuerySpec();
					var lang = langAndSpec[0];
					var spec = langAndSpec[1];

					specs[lang] = spec;
			});

			return specs;
	},

  /* Event handlers */

  onAddLanguageClicked: function() {
		var bar = this.createLanguageBar();
		bar.getTopToolbar().deleteLanguageButton.enable();
    this.add(bar);
		this.doLayout();
  },

  onSearchClicked: function() {
		var spec = this.getQuerySpec();

		// first language is the basis of the query
		var corpus = this.languageBars[0].getSelectedLanguage();
			
    App.Controller.search(corpus, spec);
  },

	removeLanguageBar: function(bar) {
		this.deregisterLanguageBar(bar);
		this.remove(bar);
	}
});
Ext.reg("searchcriteriapanel", App.Search.SearchCriteriaPanel);

