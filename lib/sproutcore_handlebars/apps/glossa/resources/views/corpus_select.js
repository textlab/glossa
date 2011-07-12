// ==========================================================================
// Project:   Glossa
// Copyright: ©2011 The Text Laboratory, University of Oslo
// Author:    Anders Nøklestad (anders.noklestad@iln.uio.no)
// ==========================================================================

sc_require('resources/views/textlab/select');

Glossa.CorpusSelectView = Textlab.SelectView.extend({
    layerId: 'corpus-select',
    name: 'corpus',
    contentBinding: 'Glossa.corporaController',
    selectionBinding: 'Glossa.corporaController.selection',
    nameKey: 'name',
    valueKey: 'code',
    emptyName: '--- Please select a corpus ---'
});
