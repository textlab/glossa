// Initialization stuff that must be performed after the ExtJS Javascript files
// have been loaded but before the rest of our own code is run

Ext.namespace('App.Search');

// Set BLANK_IMAGE_URL as required by Ext
Ext.BLANK_IMAGE_URL = urlRoot + '/images/default/s.gif';

// Required by Rails' CSRF protection
Ext.Ajax.extraParams = {authenticity_token: authenticityToken};

// Putting the authenticity token into extraParams makes POST the default
// action, but we still want it to be GET
Ext.Ajax.method = 'GET';
