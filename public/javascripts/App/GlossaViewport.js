App.GlossaViewport = Ext.extend(App.GlossaViewportUi, {
  initComponent: function() {
    // Property to keep track of SearchPanel instances for query building
    this.searchPanels = [];

    App.GlossaViewport.superclass.initComponent.call(this);

    this.setupSubcomponents();
    this.setupEventHandlers();
  },

  setupSubcomponents: function() {
    // Add an initial search panel which will not be closable
    this.addSearchPanel();
    this.doLayout();
  },

  setupEventHandlers: function() {
    this.addSearchButton.on('click', function() {
      this.addSearchPanel();
    }, this);
  },

  addSearchPanel: function() {
    var newSearchPanel = this.createSearchPanel();
    this.centerTabpanel.add(newSearchPanel);
    this.centerTabpanel.setActiveTab(newSearchPanel.id);
  },

  // function that has to be called when adding or deleting a SearchPanel
  // to the gui
  createSearchPanel: function() {
    panel = new App.Search.SearchPanel();
    this.registerSearchPanel(panel);
    return panel;
  },

  registerSearchPanel: function(panel) {
    this.searchPanels.push(panel);
  },

  // returns an object/hash that specifies the query constructed in the gui
  getQuerySpec: function() {
    // only got one SearchPanel at the moment
    return this.searchPanels[0].getQuerySpec();
  }
});
