// ==========================================================================
// Project:   Glossa.QueryRowView
// Copyright: ©2010 The Text Laboratory, University of Oslo
// ==========================================================================

sc_require('views/query_term');

/*globals Glossa */

/** @class

  (Document Your View Here)

  @extends SC.View
*/
Glossa.QueryRowView = SC.View.extend(
/** @scope Glossa.QueryRowView.prototype */ {

  classNames: 'gray-bottom-border',
  layout: { height: 150 },
  useStaticLayout: YES,
  childViews: 'languageSelector terms buttons orButton'.w(),

  languageSelector: SC.SelectFieldView.design({
    layout: { left: 8, top: 10, width: 150, height: 20 },
    objects: [{ title: 'DICKENS', value: 'DICKENS'}],
    nameKey: 'title',
    valueKey: 'value'
    //contentBinding: '.parentView.content.corpus'
  }),
  
  terms: SC.CollectionView.design({
    classNames: ['float-left'],
    layout: { left: 5, top: 35 },
    useStaticLayout: YES,
    contentBinding: '.parentView.content.terms',
    exampleView: Glossa.QueryTermView,

    // Do not perform any of the normal key event handling for this collection view;
    // just let the event pass up the responder chain
    keyDown: function() {
      return NO;
    }
  }),

  buttons: SC.View.design({
    useStaticLayout: YES,
    layout: { top: 35, width: 120, height: 80 },
    childViews: 'addButton removeButton'.w(),

    addButton: SC.ButtonView.design({
      controlSize: SC.REGULAR_CONTROL_SIZE,
      layout: { top: 24, width: 110, height: 24 },
      title: 'Add word',
      action: 'addQueryTerm',
      target: 'Glossa.searchController'
    }),
    
    removeButton: SC.ButtonView.design({
      controlSize: SC.REGULAR_CONTROL_SIZE,
      layout: { top: 50, width: 110, height: 24 },
      title: 'Remove word',
      action: 'removeQueryTerm',
      target: 'Glossa.searchController'
    })
    
  }),

  orButton: SC.ButtonView.design({
    controlSize: SC.REGULAR_CONTROL_SIZE,
    layout: { left: 10, top: 120, width: 100, height: 24 },
    title: 'Or...',
    action: 'addQueryRow',
    target: 'Glossa.searchController'
  })

});
