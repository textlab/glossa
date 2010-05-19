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
    this.add(this.createLanguageBar);
  }
});
Ext.reg("searchcriteriapanel", App.Search.SearchCriteriaPanel);

