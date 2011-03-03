// ==========================================================================
// Project:   Glossa
// Copyright: ©2011 My Company, Inc.
// ==========================================================================
/*globals Glossa */

var query = SC.Query.local(Glossa.Search);
var searches = Glossa.store.find(query);
Glossa.store.createRecord(Glossa.Search, {
    queries: [
        {corpus: 'dickens', terms: [
            {min: null, max: null, string: ''}
        ]}
    ]
}, 'new1');
Glossa.searchesArrayController.set('content', searches);

Glossa.searchesArrayController.selectObject(Glossa.searchesArrayController.lastObject());

Glossa.MyView = SC.TemplateView.create({
    classNames: 'myview'
});

jQuery(document).ready(function() {
    Glossa.mainPane = SC.TemplatePane.append({
        layerId: 'glossa',
        templateName: 'glossa'
    });
});
