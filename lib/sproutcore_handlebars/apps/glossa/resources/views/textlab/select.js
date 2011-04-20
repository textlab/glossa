// ==========================================================================
// Copyright: ©2011 The Text Laboratory, University of Oslo
// Author:    Anders Nøklestad (anders.noklestad@iln.uio.no)
// ==========================================================================

var Textlab = Textlab || {};

/* @class
 Simple view that wraps an HTML select list. Most properties are named and
 function in a similar way to corresponding properties on standard SproutCore
 views.
 */
Textlab.SelectView = SC.CoreView.extend({
    tagName: 'select',
    isEnabled: true,
    nameKey: null,
    valueKey: null,
    content: null,  // set to enumerable object or bind to controller

    displayProperties: 'content'.w(),

    render: function(context, firstTime) {
        var name = this.get('name');
        if (name) {
            context.attr('name', name);
        }
        if (!this.get('isEnabled')) {
            context.attr('disabled', 'disabled');
        }

        var content = this.get('content');
        if(content && content.get && content.get('length')) {
            var emptyName = this.get('emptyName');
            if (emptyName) {
                context.push('<option value="">' + emptyName + '</option>');
            }
            var nameKey = this.get('nameKey');
            var valueKey = this.get('valueKey');
            content.forEach(function(option) {
                var optionString = option.toString();
                context.push('<option value="%@">%@</option>'.fmt(
                        valueKey ? option.get(valueKey) : optionString,
                        nameKey ? option.get(nameKey) : optionString));
            });
        }
    }
});
