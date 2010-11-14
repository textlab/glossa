// ==========================================================================
// Project:   Glossa.QueryTermView
// Copyright: ©2010 The Text Laboratory, University of Oslo
// ==========================================================================
/*globals Glossa */

/** @class

(Document Your View Here)

@extends SC.View
*/
Glossa.QueryTermView = SC.View.extend(
  /** @scope Glossa.QueryTermView.prototype */ {

  classNames: 'float-left',
  useStaticLayout: YES,
  childViews: 'interval term'.w(),

  interval: SC.View.design({
    classNames: 'float-left',
    useStaticLayout: YES,
    layout: { width: 80, height: 70 },

    // do not show interval in front of first term
    isVisibleBinding: '.parentView.contentIndex',

    childViews: 'heading minIntervalLabel minInterval maxIntervalLabel maxInterval'.w(),

    heading: SC.LabelView.design({
      classNames: 'label group-heading'.w(),
      value: 'Interval'
    }),

    minIntervalLabel: SC.LabelView.design({
      classNames: 'label',
      layout: { top: 25, width: 50 },
      value: 'Min:'
    }),

    minInterval: SC.TextFieldView.design({
      layout: { left: 32, top: 25, width: 30, height: 20 },
      contentBinding: '.parentView.parentView.content',
      contentValueKey: 'min',
      validator: SC.Validator.Number
    }),

    maxIntervalLabel: SC.LabelView.design({
      classNames: 'label',
      layout: { top: 49, width: 50 },
      value: 'Max:'
    }),

    maxInterval: SC.TextFieldView.design({
      layout: { left: 32, top: 49, width: 30, height: 20 },
      contentBinding: '.parentView.parentView.content',
      contentValueKey: 'max',
      validator: SC.Validator.Number
    })
  }),

  term: SC.View.design({
    classNames: 'float-left',
    useStaticLayout: YES,
    layout: { width: 150, height: 70 },
    childViews: 'heading word optionsButton'.w(),

    heading: SC.LabelView.design({
      classNames: 'label group-heading'.w(),
      layout: { left: 5 },
      valueBinding: '.parentView.parentView.contentIndex',
      formatter: function(value) {
        return 'Word ' + (value + 1);
      }
    }),

    word: SC.TextFieldView.design({
      layout: { left: 5, top: 25, width: 120, height: 20 },
      contentBinding: '.parentView.parentView.content',
      contentValueKey: 'string'
    }),

    optionsButton: SC.ButtonView.design({
      layout: { left: 5, width: 80, top: 47 },
      title: 'Options...',
      action: 'myMethod',
      target: 'MyApp.Controller'
    })
  })
});
