// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults

// Prototype interface to CWB corpora.

/*
var input;
var result;
var queryId = 0;

var cols = new Ext.grid.ColumnModel([
		{ id: 'lineCol',
			header: 'line',
		  dataIndex: 'line' }
]);

var resultFields = ['line'];

var store = new Ext.data.JsonStore({
		fields: resultFields,
 		url: urlRoot + 'searches/query',
		totalProperty: 'querySize',
		root: 'data',
		id: 'resultStore'
});

var corporaListStore = new Ext.data.JsonStore({
		id: 'corporaListStore',
		fields: [ 'corpus' ],
		url: urlRoot + 'searches/corpora_list',
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
															updateCorpusInfo(record.get('corpus'));
													}
											}
										},
										new Ext.form.Label({
											id: 'corpusInfo',
											text: 'No corpus.'
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

function updateCorpusInfo(corpus) {
		Ext.ComponentMgr.get('corpusInfo').setText("Corpus " + corpus + ", ");

		Ext.Ajax.request({
				url: urlRoot + 'searches/corpus_info',
				params: { corpus: corpus },
				success: function(response, opts) {
						var label = Ext.ComponentMgr.get('corpusInfo');
						var obj = Ext.decode(response.responseText);

						label.setText(label.text + 'size: ' + obj.size + ', charset: ' + obj.charset + '.');
				}
		});
}
*/

Ext.ns('App');

// Sets up a singleton controller for the gui
// available as App.Controller
(function() {
		var Controller = Ext.extend(Object, {
				// store for LanguageBar language combo box
				languageStore: new Ext.data.JsonStore({
						id: 'corporaListStore',
						fields: [ 'corpus' ],
						url: urlRoot + 'searches/corpora_list',
						root: 'data',
						autoLoad: true
				}),
				languageValueField: 'corpus',
				languageDisplayField: 'corpus',

				// perform a search
				// used by search button handlers
				search: function(corpus, spec) {
						console.log(spec);
						console.log(corpus);

						var store = this.resultGrid.getStore();

						store.setBaseParam('query', Ext.encode(spec));
						store.setBaseParam('corpus', corpus);
						store.setBaseParam('caseInsensitive', false);
		
						store.load({ params: {
								start: 0
						}});
				},

				// the search result panel sets a reference to
				// itself here
				resultGrid: null
		});

		App.Controller = new Controller();
})()

var vp;

Ext.onReady(function() {
  vp = new App.GlossaViewport({renderTo: Ext.getBody()});
});
