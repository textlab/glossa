// ==========================================================================
// Project:   Glossa.MainDataSource
// Copyright: ©2011 The Text Laboratory, University of Oslo
// Author:    Anders Nøklestad (anders.noklestad@iln.uio.no)
// ==========================================================================
/*globals Glossa TL */

sc_require('data_sources/rails');

/** @class

 The main data source for this application. Extends our general
 data source for RESTful Rails applications.

 @extends TL.RailsDataSource
 */

Glossa.MainDataSource = TL.RailsDataSource.extend(
/** @scope Glossa.MainDataSource.prototype */ {

    // ..........................................................
    // QUERY SUPPORT
    //

    fetch: function(store, query) {

        // TODO: Add handlers to fetch data for specific queries.
        // call store.dataSourceDidFetchQuery(query) when done.

        if (query.recordType === Glossa.SearchResult) {
            SC.Request.postUrl('/searches/query').json().
                    notify(this, '_didFetchSearchResults', store, query).
                    send(Glossa.store.readDataHash(query.get('corpus_query').storeKey));
            return YES;
        }

        // Leave other queries to be handled by our general Rails data source
        sc_super();
    },

/*
    // ..........................................................
    // RECORD SUPPORT
    //

    retrieveRecord: function(store, storeKey) {

        // TODO: Add handlers to retrieve an individual record's contents
        // call store.dataSourceDidComplete(storeKey) when done.

        return NO; // return YES if you handled the storeKey
    },

    createRecord: function(store, storeKey) {

        // TODO: Add handlers to submit new records to the data source.
        // call store.dataSourceDidComplete(storeKey) when done.

        return NO; // return YES if you handled the storeKey
    },

    updateRecord: function(store, storeKey) {

        // TODO: Add handlers to submit modified record to the data source
        // call store.dataSourceDidComplete(storeKey) when done.

        return NO; // return YES if you handled the storeKey
    },

    destroyRecord: function(store, storeKey) {

        // TODO: Add handlers to destroy records on the data source.
        // call store.dataSourceDidDestroy(storeKey) when done

        return NO; // return YES if you handled the storeKey
    },
*/


    /** @private */
    _didFetchSearchResults: function(response, store, query) {
        var storeKeys = store.loadRecords(query.get('recordType'), response.body().data);
        store.loadQueryResults(query, storeKeys);
    }

});
