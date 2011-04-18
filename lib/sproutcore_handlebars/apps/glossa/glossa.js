// ==========================================================================
// Project:   Glossa
// Copyright: ©2011 The Text Laboratory, University of Oslo
// Author:    Anders Nøklestad (anders.noklestad@iln.uio.no)
// ==========================================================================
/*globals Glossa */

//var query = SC.Query.local(Glossa.Search);
//var searches = Glossa.store.find(query);
//Glossa.store.createRecord(Glossa.Search, {
//    queries: [
//        {corpus: 'dickens', terms: [
//            {min: null, max: null, string: ''}
//        ]}
//    ]
//}, 'new1');
//Glossa.searchesArrayController.set('content', searches);
//
//Glossa.searchesArrayController.selectObject(Glossa.searchesArrayController.lastObject());

SC.ready(function() {
//    var corporaQuery = SC.Query.local(Glossa.Corpus);
//    var corpora = Glossa.store.find(corporaQuery);
//    Glossa.corporaController.set('content', corpora);

    Glossa.mainPane = SC.TemplatePane.append({
        layerId: 'glossa',
        templateName: 'glossa'
    });
});
