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

  classNames: 'gray-border',
  layout: { height: 115 },
  useStaticLayout: YES,
  childViews: 'languageSelector terms buttons'.w(),

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
    exampleView: Glossa.QueryTermView
  }),

  buttons: SC.View.design({
    useStaticLayout: YES,
    layout: { top: 35, width: 110, height: 80 },
    childViews: 'addButton removeButton'.w(),

    addButton: SC.ButtonView.design({
      layout: { left: 0, top: 25 },
      title: 'Add word',
      action: 'addQueryTerm',
      target: 'Glossa.searchController'
    }),
    
    removeButton: SC.ButtonView.design({
      layout: { left: 0, top: 50 },
      title: 'Remove word',
      action: 'removeQueryTerm',
      target: 'Glossa.searchController'
    })
    
  })

});
