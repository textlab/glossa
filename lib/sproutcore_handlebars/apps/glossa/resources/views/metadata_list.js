// ==========================================================================
// Project:   Glossa
// Copyright: ©2011 The Text Laboratory, University of Oslo
// Author:    Anders Nøklestad (anders.noklestad@iln.uio.no)
// ==========================================================================

Glossa.MetadataListView = SC.TemplateView.extend({
    templateName: 'metadata_list',
    classNames: 'metadata-list ui-widget-content',

    content: [SC.Object.create({
        name: 'Author',
        id1: 'author1',
        id2: 'author2'
    }), SC.Object.create({
        name: 'Publisher',
        id1: 'publisher1',
        id2: 'publisher2'
    })],

    heidu: 'lahla'
});
