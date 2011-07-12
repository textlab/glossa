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
 to either a selection or a value (but not both at the same time). This means
 that it can be used either like a collection view or as a traditional form
 select. Also unlike SC.SelectFieldView, it can be rendered either as a
 single-select element (i.e., a drop-down list) or as a multi-select element.
 */
Textlab.SelectView = SC.CoreView.extend({
    tagName: 'select',

    /**
     *  Set to YES to create a multi-select; set to NO to create a single-select
     *  (drop-down menu).
     */
    multiple: NO,
    isEnabled: YES,

    /**
     * An array of content objects. Usually you will want to bind this property
     * to a controller property that actually contains the array of objects
     * you want to display.
     *
     * @property {SC.Array}
     */
    content: null,

    /**
     * If you set this to a non-null value, then the name shown for each select
     * option will be pulled from the object using the named property. If this
     * is null, the collection objects themselves will be used.
     *
     * @property {String}
     */
    nameKey: null,

    /**
     * If you set this to a non-null value, then the value attribute of each select
     * option will be pulled from the object using the named property. If this
     * is null, the collection objects themselves will be used.
     *
     * @property {String}
     */
    valueKey: null,

    displayProperties: 'content name multiple isEnabled emptyName nameKey valueKey'.w(),

    init: function() {
        // Single selects should be constrained to single selection bindings
        if (!this.multiple && this.selectionBindingDefault === undefined) {
            this.selectionBindingDefault = SC.Binding.single();
        }
        sc_super();
    },

    render: function(context) {
        var name = this.get('name');
        if (name) {
            context.attr('name', name);
        }
        if (this.get('multiple')) {
            context.attr('multiple', 'multiple');
        }
        if (!this.get('isEnabled')) {
            context.attr('disabled', 'disabled');
        }

        var content = this.get('content'),
                selectionArray = SC.A(this.get('selection'));
        if (content && content.get && content.get('length')) {
            var emptyName = this.get('emptyName'),
                    nameKey = this.get('nameKey'),
                    valueKey = this.get('valueKey'),
                    selection = valueKey ? selectionArray.mapProperty(valueKey) : selectionArray.map(function(item) {
                        return item.toString();
                    });
            if (emptyName) {
                context.push('<option value="">' + emptyName + '</option>');
            }
            content.forEach(function(option) {
                var optionString = option.toString(),
                        name = nameKey ? option.get(nameKey) : optionString,
                        value = valueKey ? option.get(valueKey) : optionString,
                        selectedStr = selection.contains(value) ? ' selected="selected"' : '';
                context.push('<option value="%@"%@>%@</option>'.fmt(value, selectedStr, name));
            });
        }
    },

    didCreateLayer: function() {
        var input = this.$();

        // Setup event listener for selection change (since SC itself
        // does not register for the change event, using a change method
        // on the view will not work).
        input.change($.proxy(function() {
            // Get the new value from the select list
            this._value = input.val();

            // Notify any observers that the value has changed
            SC.RunLoop.begin();
            this.notifyPropertyChange('value');
            SC.RunLoop.end();
        }, this));
    },

    /**
     * The value of the select element. An array of strings.
     * @property {Array}
     */
    value: function(key, value) {
        if (value !== undefined) {
            this._value = SC.A(value);
            this.$().val(value);
        } else {
            value = this._value;
        }
        return value;
    }.property().cacheable(),

    /**
     * Indexes of selected content objects. This SC.SelectionSet is modified
     * automatically by the select view when the user changes the selection in
     * the list.
     *
     * @property {SC.SelectionSet}
     */
    selection: function(key, value) {
        if (value !== undefined) {
            this._setSelectionFrom(value);
            this.notifyPropertyChange('value');
            this.displayDidChange();
        } else {
            value = this._getSelection();
        }
        return value;
    }.property.cacheable(),

    /** @private
     Used internally to store the value of the select element (i.e., the array of
     +value+ attributes for selected items).
     */
    _value: [],

    /** @private **/
    _setSelectionFrom: function(value) {
        // Transform the given selection set to an array and assign it to our
        // private +_value+ property
        var selection = value,
                valueKey = this.get('valueKey'),
                multiple = this.get('multiple');
        this._value = multiple ?
                (valueKey ? selection.getEach(valueKey) : selection.toArray()) :
                (valueKey ? selection.get(valueKey) : selection.toString());
    },

    /** @private **/
    _getSelection: function() {
        // Transform our private +_value+ property to a selection set
        // TODO: What if valueKey is null?
        var content = this.get('content'),
                valueKey = this.get('valueKey'),
                objects = this._value.map(function(value) {
                    return content.findProperty(valueKey, value);
                });
        return SC.SelectionSet.create().addObjects(objects);
    }

});
