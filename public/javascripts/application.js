// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults

// Prototype interface to CWB corpora.

// NOTE: this must be set, should be a configuration setting
// TODO: remove this
var serverUrl = 'http://localhost:3000/'

var input;
var result;
var queryId = 0;
var debug = null;

var cols = new Ext.grid.ColumnModel([
		{ id: 'lineCol',
			header: 'line',
		  dataIndex: 'line' }
]);

var resultFields = ['line'];

var store = new Ext.data.JsonStore({
		fields: resultFields,
 		url: serverUrl + 'searches/query',
		totalProperty: 'querySize',
		root: 'data',
		id: 'resultStore'
});

var corporaListStore = new Ext.data.JsonStore({
		id: 'corporaListStore',
		fields: [ 'corpus' ],
		url: serverUrl + 'searches/corpora_list',
		root: 'data',
		autoLoad: true
});

var pager = {
		xtype: 'paging',
		store: store,
		pageSize: 5
};

var gridView = new Ext.grid.GridView();

var sel = new Ext.grid.RowSelectionModel({ singleSelect: true });

var lineGrid = new Ext.grid.GridPanel({
		store: store,
		colModel: cols,
		selModel: sel,
		view: gridView,
		autoHeight: true,
		bbar: pager,
		autoExpandColumn: 'lineCol'
});

function buttonHandler() {
		queryId = 0;
		
		store.setBaseParam('query', Ext.get('input').getValue());
		store.setBaseParam('corpus', Ext.get('corporaSelection').getValue());
		store.setBaseParam('caseInsensitive', Ext.get('caseInsensitive').getValue())
		
		store.load({ params: {
				start: 0,
				limit: 5
		}});
}

Ext.onReady(function() {
		var viewPort = new Ext.Viewport({
				id: 'rootView',
				items: [{
						xtype: 'panel',
						title: 'Query',
						items: [{ xtype: 'textfield', id: 'input' },
										{ xtype: 'combo',
											id: 'corporaSelection',
											store: corporaListStore,
											displayField: 'corpus',
											valueField: 'corpus',
											triggerAction: 'all',
											forceSelection: true,
											selectOnFocus: true,
											typeAhead:true,
											loadingText: 'Querying...',
											minChars: 1,
											listeners: {
													select: function(combo, record, index) {
															var newValue = record.get('corpus');
															Ext.ComponentMgr.get('corpusInfo').setText("Corpus info (" + newValue + "):");
													}
											}
										},
										new Ext.form.Label({
											id: 'corpusInfo',
											text: 'Corpus info:'
										}),
										{
												xtype: 'checkbox',
												id: 'caseInsensitive',
												checked: true,
												boxLabel: 'Case insensitive'
										},
										{ xtype: 'button', text: 'Query', handler: buttonHandler }]},
					  lineGrid]
		});

		store.proxy.on('beforeload', function(proxy, params) {
				// insert the query id before calling the server
				// changes between the initial request and further
				// paging so it must be reevalueted on each call
				params.queryId = queryId;

				return true;
		});

		store.on('load', function(store, records, options) {
				// save the returned query id for use in fex. paging
				queryId = store.reader.jsonData.queryId;

				return true;
		});

		viewPort.show();
});
