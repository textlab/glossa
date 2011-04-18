// ==========================================================================
// Project:   Glossa
// Copyright: ©2011 The Text Laboratory, University of Oslo
// Author:    Anders Nøklestad (anders.noklestad@iln.uio.no)
// ==========================================================================

sc_require('resources/views/textlab/border_layout');

Glossa.MainBorderLayoutView = Textlab.BorderLayoutView.extend({
    regions: {
        center: {
            id: 'main-center-region'
        },
        north: {
            id: 'main-north-region',
            resizable: true
        },
        west: {
            id: 'main-west-region',
            resizable: true
        },
        south: {
            id: 'main-south-region'
        }
    },
    logoUrl: sc_static('images/tl_grey_115x18.gif')
});

