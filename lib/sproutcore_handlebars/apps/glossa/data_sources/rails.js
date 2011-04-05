// ==========================================================================
// Project:   TL.RailsDataSource
// Copyright: ©2011 The Text Laboratory, University of Oslo
// Author:    Anders Nøklestad (anders.noklestad@iln.uio.no)
// ==========================================================================
/*globals TL */

/** @class

 General data source for RESTful Rails applications.

 @extends SC.DataSource
 */

var TL = TL || {};

TL.RailsDataSource = SC.DataSource.extend(
/** @scope TL.RailsDataSource.prototype */ {

    // ..........................................................
    // QUERY SUPPORT
    //

    fetch: function(store, query) {

        // TODO: Add handlers to fetch data for specific queries.
        // call store.dataSourceDidFetchQuery(query) when done.

        var recordType = query.get('recordType'),
            pluralResourcePath = this._getPluralResourcePathFor(recordType);

        if(pluralResourcePath) {
            SC.Request.getUrl(pluralResourcePath).json().notify(this, '_fetchDidComplete', store, query).send();
            return YES;
        } else return NO;
    },

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

        var recordType = store.recordTypeFor(storeKey),
            data = store.readDataHash(storeKey);

        SC.Request.postUrl('/%@'.fmt(this._getPluralResourcePathFor(recordType)))
                .notify(this, '_createRecordDidComplete', store, storeKey)
                .json().send(data);

        return YES;
    },

    updateRecord: function(store, storeKey) {

        // TODO: Add handlers to submit modified record to the data source
        // call store.dataSourceDidComplete(storeKey) when done.

        var recordType = store.recordTypeFor(storeKey),
            id = store.idFor(storeKey),
            data = store.readDataHash(storeKey);

        SC.Request.putUrl("/%@/%@".fmt(this._getSingularResourcePathFor(recordType), id))
                .notify(this, '_updateRecordDidComplete', store, storeKey)
                .json().send(data);

        return YES;
    },

    destroyRecord: function(store, storeKey) {

        // TODO: Add handlers to destroy records on the data source.
        // call store.dataSourceDidDestroy(storeKey) when done

        var recordType = store.recordTypeFor(storeKey),
            id = store.idFor(storeKey);

        SC.Request.deleteUrl('/%@/%@'.fmt(this._getSingularResourcePathFor(recordType), id))
                .notify(this, '_destroyRecordDidComplete', store, storeKey)
                .json().send();

        return YES;
    },

    /** @private */

    _fetchDidComplete: function(response, store, query) {
        if(SC.ok(response)) {
            var recordType = query.get('recordType'),
                records = response.get('body').data;

            store.loadRecords(recordType, records);
            store.dataSourceDidFetchQuery(query);
        } else {
            store.dataSourceDidErrorQuery(query, response);
        }
    },

    _createRecordDidComplete: function(response, store, storeKey) {
        var body = response.get('body');

        if(SC.ok(response) && body.success) {
            store.dataSourceDidComplete(storeKey, null, body.id)
        } else {
            store.dataSourceDidError(storeKey, response);
        }
    },


    _updateRecordDidComplete: function(response, store, storeKey) {
        var body = response.get('body');

        if(SC.ok(response) && body.success) {
            if(body.data) {
                // We got updated record data from the server; tell the store about it
                store.dataSourceDidComplete(storeKey, body.data);
            }
            else {
                // No record data received from the server, so just tell the store we're OK
                store.dataSourceDidComplete(storeKey);
            }
        } else {
            // Error from server
            store.dataSourceDidError(storeKey, response);
        }
    },

    _destroyRecordDidComplete: function(response, store, storeKey) {
        var body = response.get('body');
    },


    _getSingularResourcePathFor: function(recordType) {
        // Unless the record class has a singularResourcePath property, take the last part of its class name
        // and change it from camel case to underscored (e.g. "MyApp.MyModel" becomes "my_model").
        return recordType.singularResourcePath || recordType.toString().split('.').lastObject().decamelize();
    },

    _getPluralResourcePathFor: function(recordType) {
        // Unless the record class has a pluralResourcePath property, pluralize its singular resource path
        // (for class names with irregular plurals, set the pluralResourcePath property on the class).
        return recordType.pluralResourcePath || this._getSingularResourcePathFor(recordType) + 's';
    }

});
