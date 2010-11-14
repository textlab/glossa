// ==========================================================================
// Project:   Glossa.RailsDataSource
// Copyright: ©2010 The Text Laboratory, University of Oslo
// ==========================================================================
/*globals Glossa */

/** @class

  (Document Your Data Source Here)

  @extends SC.DataSource
*/
Glossa.RailsDataSource = SC.DataSource.extend(
/** @scope Glossa.RailsDataSource.prototype */ {

  // ..........................................................
  // QUERY SUPPORT
  // 

  fetch: function(store, query) {

    // TODO: Add handlers to fetch data for specific queries.  
    // call store.dataSourceDidFetchQuery(query) when done.

    if(query.recordType === Glossa.SearchResult) {
      SC.Request.postUrl('/searches/query').json().
        notify(this, '_didFetchSearchResults', {store: store, query: query}).
          send(Glossa.store.readDataHash(query.get('corpus_query').storeKey));
      return YES;
    }

    return NO ; // return YES if you handled the query
  },

  // ..........................................................
  // RECORD SUPPORT
  // 
  
  retrieveRecord: function(store, storeKey) {
    
    // TODO: Add handlers to retrieve an individual record's contents
    // call store.dataSourceDidComplete(storeKey) when done.
    
    return NO ; // return YES if you handled the storeKey
  },
  
  createRecord: function(store, storeKey) {
    
    // TODO: Add handlers to submit new records to the data source.
    // call store.dataSourceDidComplete(storeKey) when done.
    
    return NO ; // return YES if you handled the storeKey
  },
  
  updateRecord: function(store, storeKey) {
    
    // TODO: Add handlers to submit modified record to the data source
    // call store.dataSourceDidComplete(storeKey) when done.

    return NO ; // return YES if you handled the storeKey
  },
  
  destroyRecord: function(store, storeKey) {
    
    // TODO: Add handlers to destroy records on the data source.
    // call store.dataSourceDidDestroy(storeKey) when done
    
    return NO ; // return YES if you handled the storeKey
  },


  /** @private */
  _didFetchSearchResults: function(response, params) {
    var storeKeys = params.store.loadRecords(Glossa.SearchResult, response.body().data);
    params.store.loadQueryResults(params.query, storeKeys);
  }
  
}) ;
