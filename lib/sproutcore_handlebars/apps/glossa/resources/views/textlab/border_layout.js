// ==========================================================================
// Copyright: ©2011 The Text Laboratory, University of Oslo
// Author:    Anders Nøklestad (anders.noklestad@iln.uio.no)
// ==========================================================================

var Textlab = Textlab || {};

/* @class
    Implements a border layout similar to what is found in, e.g., the ExtJS library.
    A border layout contains regions, of which only the center region is obligatory,
    while north, west, east, and south regions are optional.

    Regions can be identified either by HTML classes named tl-center-region, tl-west-region
    etc., or by ids in a +regions+ property that is set on a class instance (see documentation
    below). Likewise, whether a region is resizable can be determined either using a
    tl-resizable HTML class or by setting the +reizable+ flag in the configuration property.
 */
Textlab.BorderLayoutView = SC.TemplateView.extend({
    classNames: 'tl-border-layout',

    /*
    Configuration options for regions. The keys are region names (north, west, east,
    south, or center), and the available options are as follows:
        - id {String}: id attribute that identifies the HTML element that constitutes
              the region. This is an alternative to using a class name such as tl-north-region,
              tl-west-region etc.
        - resizable {Boolean}: Whether or not the region should be resizable. Alternative
              to using a tl-resizable class to indicate resizable regions.
    @property {Object}
     */
    regions: {},

    // When the BorderLayoutView has been appended to the document, the various
    // regions will finally have got their layout, so now we can reposition them.
    didAppendToDocument: function() {
        this.centerRegion$ = this.$(this.regions.center && this.regions.center.id ?
                '#' + this.regions.center.id : '> .tl-center-region');
        this.northRegion$ = this.$(this.regions.north && this.regions.north.id ?
                '#' + this.regions.north.id : '> .tl-north-region');
        this.westRegion$ = this.$(this.regions.west && this.regions.west.id ?
                '#' + this.regions.west.id : '> .tl-west-region');
        this.eastRegion$ = this.$(this.regions.east && this.regions.east.id ?
                '#' + this.regions.east.id : '> .tl-east-region');
        this.southRegion$ = this.$(this.regions.south && this.regions.south.id ?
                '#' + this.regions.south.id : '> .tl-south-region');

        if (!this.centerRegion$.length) {
            SC.Logger.error('Textlab.BorderLayoutView: No center region defined!');
            return;
        }

        this._positionRegions();
        this._makeRegionsResizable();
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
    },

    /* @private */
    _makeRegionsResizable: function() {
        if ((this.regions.north && this.regions.north.resizable) ||
                this.northRegion$.hasClass('tl-resizable')) {
            // Apply the +resizable+ jQuery UI interaction to the region
            this.northRegion$.resizable({
                handles: 's',
                start: $.proxy(function() {
                    // If the west or east regions have been resized earlier, they will
                    // have been given an explicit height by the +resizable+ interaction.
                    // We have to remove that to allow them to keep flowing down to the
                    // south region (or the bottom of the BorderLayoutView) as we resize
                    // the north region.
                    this.westRegion$.css({ height: '' });
                    this.eastRegion$.css({ height: '' });
                }, this),
                resize: $.proxy(function() {
                    // Adjust the top of the west, center, and east regions as the north region is resized
                    var height = this.northRegion$.height();
                    this.westRegion$.css({ top: height });
                    this.centerRegion$.css({ top: height });
                    this.eastRegion$.css({ top: height });
                }, this)
            });
        }

        // Same procedure for the other regions
        if ((this.regions.west && this.regions.west.resizable) ||
                this.westRegion$.hasClass('tl-resizable')) {
            this.westRegion$.resizable({ handles: 'e', resize: $.proxy(function() {
                // Resizing the west or east regions only affects the center region
                this.centerRegion$.css({ left: this.westRegion$.width() });
            }, this)});
        }

        if ((this.regions.east && this.regions.east.resizable) ||
                this.eastRegion$.hasClass('tl-resizable')) {
            this.eastRegion$.resizable({ handles: 'w', resize: $.proxy(function() {
                this.centerRegion$.css({ right: this.eastRegion$.width() });
            }, this)});
        }

        if ((this.regions.south && this.regions.south.resizable) ||
                this.southRegion$.hasClass('tl-resizable')) {
            this.southRegion$.resizable({
                handles: 'n',
                start: $.proxy(function() {
                    this.westRegion$.css({ height: '' });
                    this.eastRegion$.css({ height: '' });
                }, this),
                resize: $.proxy(function() {
                    var height = this.southRegion$.height();
                    this.westRegion$.css({ bottom: height });
                    this.centerRegion$.css({ bottom: height });
                    this.eastRegion$.css({ bottom: height });
                }, this)
            });
        }
    }
});
