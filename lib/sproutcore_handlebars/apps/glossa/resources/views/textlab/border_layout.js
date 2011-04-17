// ==========================================================================
// Copyright: ©2011 The Text Laboratory, University of Oslo
// Author:    Anders Nøklestad (anders.noklestad@iln.uio.no)
// ==========================================================================

var Textlab = Textlab || {};

Textlab.BorderLayoutView = SC.TemplateView.extend({
    classNames: 'tl-border-layout',

    // When the BorderLayoutView has been appended to the document, the various
    // regions will finally have got their layout, so now we can reposition them.
    didAppendToDocument: function() {
        this.centerRegion$ = this.$('> .tl-center-region');
        this.northRegion$ = this.$('> .tl-north-region');
        this.westRegion$ = this.$('> .tl-west-region');
        this.eastRegion$ = this.$('> .tl-east-region');
        this.southRegion$ = this.$('> .tl-south-region');

        if (!this.centerRegion$.length) {
            SC.Logger.error('Textlab.BorderLayoutView: No center region defined!');
            return;
        }

        this._positionRegions();
    },

    /* @private */

    _positionRegions: function() {
        this.northRegion$.css({
            position: 'absolute',
            top: 0,
            left: 0,
            right: 0
        });

        this.westRegion$.css({
            position: 'absolute',
            left: 0,
            top: this.northRegion$.length ? this.northRegion$.outerHeight(true) : 0,
            bottom: this.southRegion$.length ? this.southRegion$.outerHeight(true) : 0
        });

        this.eastRegion$.css({
            position: 'absolute',
            right: 0,
            top: this.northRegion$.length ? this.northRegion$.outerHeight(true) : 0,
            bottom: this.southRegion$.length ? this.southRegion$.outerHeight(true) : 0
        });

        this.southRegion$.css({
            position: 'absolute',
            bottom: 0,
            left: 0,
            right: 0
        });

        this.centerRegion$.css({
            position: 'absolute',
            top: this.northRegion$.length ? this.northRegion$.outerHeight(true) : 0,
            left: this.westRegion$.length ? this.westRegion$.outerWidth(true) : 0,
            right: this.eastRegion$.length ? this.eastRegion$.outerWidth(true) : 0,
            bottom: this.southRegion$.length ? this.southRegion$.outerHeight(true) : 0
        })
    }
});
