App.Search.IntervalFieldSet = Ext.extend(App.Search.IntervalFieldSetUi, {
    initComponent: function() {
        App.Search.IntervalFieldSet.superclass.initComponent.call(this);
    },

		// collects the min and max values from the gui into an object
		getInterval: function() {
				var values = new Array();
				this.items.each(function(f, i) { values.push(f.getValue())});

				return { min: values[0], max: values[1] }
		},

		// returns the query sub spec for this interval
		getQuerySpec: function() {
				var spec = this.getInterval();
				spec.type = 'interval';

				return spec;
		}
});
Ext.reg("intervalfieldset", App.Search.IntervalFieldSet);
