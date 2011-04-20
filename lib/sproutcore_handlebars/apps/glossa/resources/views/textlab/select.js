// ==========================================================================
// Copyright: ©2011 The Text Laboratory, University of Oslo
// Author:    Anders Nøklestad (anders.noklestad@iln.uio.no)
// ==========================================================================

var Textlab = Textlab || {};

/* @class
 Simple view that wraps an HTML select list. Most properties are named and
 function in a similar way to corresponding properties on standard SproutCore
 views.

 Unlike the built-in SC.SelectFieldView, Textlab.SelectView supports binding
 to a selection as well as to a value. This means that it can be used either
 like a collection view or as a traditional form select. Also unlike
 SC.SelectFieldView, it can be rendered either as a single-select element
 (i.e., a drop-down list) or as a multi-select element.
 */
Textlab.SelectView = SC.CoreView.extend({
    tagName: 'select',
    multiple: NO,
    isEnabled: YES,
    nameKey: null,
    valueKey: null,
    content: null,  // set to enumerable object or bind to controller

    displayProperties: 'content'.w(),

    /** @private
     Used internally to store value because the layer may not exist.
     */
    _value: null,

    init: function() {
        // Single selects should be constrained to single selection bindings
        if (!this.multiple && this.selectionBindingDefault === undefined) {
            this.selectionBindingDefault = SC.Binding.single();
        }
        sc_super();
    },


    render: function(context, firstTime) {
        var name = this.get('name');
        if (name) {
            context.attr('name', name);
        }
        if (!this.get('isEnabled')) {
            context.attr('disabled', 'disabled');
        }

        var content = this.get('content');
        if (content && content.get && content.get('length')) {
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
    },

    didCreateLayer: function() {
        var input = this.$();

        // Do the actual selection in the list if our value is set
        if (this._value !== null) {
            input.val(this._value);
        }

        // Setup event listener for selection change
        input.change($.proxy(function() {
            // Notify any observers that the value has changed.
            SC.RunLoop.begin();
            this.notifyPropertyChange('value');
            SC.RunLoop.end();
        }, this));
    },

    /**
     * The value of the select element. For multi-select elements, this is an
     * array of strings; otherwise it is a single string.
     * @property {String|Array}
     */
    value: function(key, value) {
        var input = this.$();
        if (value !== undefined) {
            this._value = value;
            input.val(value);
        } else {
            if (input.length > 0) {
                value = this._value = input.val();
            } else {
                value = this._value;
            }
        }
        return value;
    }.property().idempotent()
});
