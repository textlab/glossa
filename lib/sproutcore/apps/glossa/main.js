// ==========================================================================
// Project:   Glossa
// Copyright: ©2010 The Text Laboratory, University of Oslo
// ==========================================================================
/*globals Glossa */

// This is the function that will start your app running.  The default
// implementation will load any fixtures you have created then instantiate
// your controllers and awake the elements on your page.
//
// As you develop your application you will probably want to override this.
// See comments for some pointers on what to do next.
//
Glossa.main = function main() {

  // Step 1: Instantiate Your Views
  // The default code here will make the mainPane for your application visible
  // on screen.  If you app gets any level of complexity, you will probably 
  // create multiple pages and panes.  
  Glossa.getPath('mainPage.mainPane').append() ;

  // Step 2. Set the content property on your primary controller.
  // This will make your app come alive!

  // TODO: Set the content property on your primary controller
  // example: Glossa.contactsController.set('content',Glossa.contacts);

  var query = SC.Query.local(Glossa.Search);
  var searches = Glossa.store.find(query);
  Glossa.store.createRecord(Glossa.Search, {
    queries: [{corpus: 'dickens', terms: [{min: null, max: null, string: ''}]}]
  }, 'new1');
  Glossa.searchesArrayController.set('content', searches);

  Glossa.searchesArrayController.selectObject(Glossa.searchesArrayController.lastObject());

} ;

function main() { Glossa.main(); }
