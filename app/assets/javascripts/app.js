// Set BLANK_IMAGE_URL as required by Ext
Ext.BLANK_IMAGE_URL = urlRoot + '/images/s.gif';

Ext.Loader.setConfig({
    enabled: true,
    paths: {
        'Ext': 'assets/extjs/src'  // make dynamic loading play nicely with the asset pipeline
    }
});

// Required by Rails' CSRF protection
Ext.require('Ext.Ajax', function() {
    Ext.Ajax.extraParams = {authenticity_token: authenticityToken};

    // Putting the authenticity token into extraParams makes POST the default
    // action, but we still want it to be GET
    Ext.Ajax.method = 'GET';
});

Ext.application({
    name: 'Glossa',

    launch: function() {
        Ext.create('Ext.container.Viewport', {
            layout: 'border',
            items: [{
                region: 'center',
                xtype: 'panel',
                title: 'Test',
                html: 'Tester'
            }]
        });
    }
});
