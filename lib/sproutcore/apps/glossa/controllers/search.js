// ==========================================================================
// Project:   Glossa.searchController
// Copyright: ©2010 The Text Laboratory, University of Oslo
// ==========================================================================
/*globals Glossa */

/** @class

  (Document Your Controller Here)

  @extends SC.Object
*/
Glossa.searchController = SC.ObjectController.create(
/** @scope Glossa.searchController.prototype */ {

  contentBinding: SC.Binding.single('Glossa.searchesArrayController.selection'),


  // Action for "Add word" buttons
  addQueryTerm: function(button) {
    // Find the data array for the query row that the clicked button belongs to
    var queryRowTerms = this._getQueryRowTerms(button);

    // Add a query term hash to that array
    queryRowTerms.pushObject(this._createQueryTermHash());
  },


  // Action for "Remove word" buttons
  removeQueryTerm: function(button) {
    // Find the data array for the query row that the clicked button belongs to
    var queryRowTerms = this._getQueryRowTerms(button);

    // Remove the last query term hash for that row (unless it is also the first one),
    // which will also remove the query term view that is bound to it
    if(queryRowTerms.get('length') > 1) {
      queryRowTerms.popObject();
    }
  },


  // Perform a search
  search: function() {
    var query = SC.Query.remote(Glossa.SearchResult,
                                {corpus_query: Glossa.searchController.get('content')});
    var results = Glossa.store.find(query);

    Glossa.searchResultsArrayController.set('content', results);
    var tabView = Glossa.mainPage.mainPane.tabView;
    tabView.set('nowShowing', tabView.get('items').objectAt(1)['value']);
  },


  /** @private */
  _getQueryRowTerms: function(button) {
    var queryRowViewIndex = button.parentView.parentView.contentIndex;
    return this.get('content').get('queries').objectAt(queryRowViewIndex).get('terms');
  },


  /** @private */
  _createQueryTermHash: function() {
    return {min: null, max: null, word: ''};
  }

}) ;
