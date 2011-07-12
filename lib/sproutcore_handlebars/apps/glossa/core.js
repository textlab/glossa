// ==========================================================================
// Project:   Glossa
// Copyright: ©2011 The Text Laboratory, University of Oslo
// Author:    Anders Nøklestad (anders.noklestad@iln.uio.no)
// ==========================================================================
/*globals Glossa */

/** @namespace

  SproutCore client application for the Glossa corpus search and results
  management system.

  @extends SC.Object
*/
Glossa = SC.Application.create(
  /** @scope Glossa.prototype */ {

  NAMESPACE: 'Glossa',
  VERSION: '0.1.0',

  // This is your application store.  You will use this store to access all
  // of your model data.  You can also set a data source on this store to
  // connect to a backend server.  The default setup below connects the store
  // to any fixtures you define.
//  store: SC.Store.create().from('Glossa.MainDataSource')
    store: SC.Store.create().from(SC.Record.fixtures)

  // TODO: Add global constants or singleton objects needed by your app here.

}) ;
