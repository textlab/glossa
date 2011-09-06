// Set BLANK_IMAGE_URL as required by Ext
Ext.BLANK_IMAGE_URL = urlRoot + '/images/s.gif';

// Required by Rails' CSRF protection
Ext.Ajax.extraParams = {authenticity_token: authenticityToken};

// Putting the authenticity token into extraParams makes POST the default
// action, but we still want it to be GET
Ext.Ajax.method = 'GET';

Ext.Loader.setConfig({
    enabled: true
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
