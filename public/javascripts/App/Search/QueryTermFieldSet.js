App.Search.QueryTermFieldSet = Ext.extend(App.Search.QueryTermFieldSetUi, {
    initComponent: function() {
        App.Search.QueryTermFieldSet.superclass.initComponent.call(this);
    },

		// returns the string contained in the word input field
		getTermString: function() {
				return this.items.first().getValue();
		},

		// returns the query sub spec for this term
		getQuerySpec: function() {
				return { type: 'word', string: this.getTermString() }
		}
});
Ext.reg("querytermfieldset", App.Search.QueryTermFieldSet);
