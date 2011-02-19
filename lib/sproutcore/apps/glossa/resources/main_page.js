// ==========================================================================
// Project:   Glossa - mainPage
// Copyright: ©2010 The Text Laboratory, University of Oslo
// ==========================================================================

sc_require('views/query_row');

/*globals Glossa */

// This page describes the main user interface for your application.
Glossa.mainPage = SC.Page.design({

  // The main pane is made visible on screen as soon as your app is loaded.
  // Add childViews to this pane for views to display immediately on page
  // load.
  mainPane: SC.MainPane.design({
    childViews: 'topbar splitView'.w(),
    mainSceneView: SC.outlet('splitView.bottomRightView'),

    topbar: SC.View.design({
      layout: { height: 30 },
      classNames: 'topbar'.w(),
      childViews: 'glossaLogo textlabLogo'.w(),

      glossaLogo: SC.LabelView.design({
        layout: { centerY: 0, height: 24, left: 10 },
        controlSize: SC.LARGE_CONTROL_SIZE,
        value: 'Glossa'
      }),

      textlabLogo: SC.ImageView.design({
        layout: { right: 10, centerY: 0, width: 110, height: 24 },
        value: 'http://www.tekstlab.uio.no/nota/img/tllogo_110x24_bw_glowwhite.png'
      })
    }),

    splitView: SC.SplitView.design({
      layout: { top: 31 },
      defaultThickness: 200,
      layoutDirection: SC.LAYOUT_HORIZONTAL,
      dividerThickness: 1,

      topLeftView: SC.ListView.design({
        layout: {  },
        classNames: 'source-list'.w(),
        contentBinding: 'MyApp.controller.arrangedObjects',
        selectionBinding: 'MyApp.controller.selection'
      }),

      //dividerView: SC.SplitDividerView.design(),

      bottomRightView: SC.SceneView.design({
        layout: {  },
        scenes: 'Glossa.searchView Glossa.resultsView'.w(),
        nowShowing: 'Glossa.searchView',
        transitionDuration: 200
      })
    })
  })

});

// The content views of Glossa.mainPage.mainPane.tabView. These cannot be defined
// within Glossa.mainPage because it leads to infinite recursion if nowShowing
// is set (since Glossa.mainPage and all its child panels will be created then, including
// the TabView, which leads to setting of nowShowing, which leads to creation of Glossa.mainPage
// etc. ad infinitum...).
Glossa.searchView = SC.View.design({
  childViews: 'buttons queryRows'.w(),

  buttons: SC.View.design({
    layout: { top: 10, height: 32 },
    classNames: 'gray-bottom-border'.w(),
    childViews: 'resetButton searchButton'.w(),

    resetButton: SC.ButtonView.design({
      controlSize: SC.REGULAR_CONTROL_SIZE,
      layout: { left: 10, width: 100, height: 24 },
      title: 'Reset form',
      action: 'myMethod',
      target: 'MyApp.Controller'
    }),

    searchButton: SC.ButtonView.design({
      controlSize: SC.REGULAR_CONTROL_SIZE,
      layout: { left: 120, width: 100, height: 24 },
      title: 'Search',
      action: 'search',
      target: 'Glossa.searchController',
      isDefault: YES
    })
  }),

  queryRows: SC.ScrollView.design({
    layout: { top: 45, right: 0, bottom: 0, left: 0 },

    contentView: SC.CollectionView.design({
      contentBinding: 'Glossa.searchController.queries',

      // Each QueryRowView contains a horizontal sequence of query terms
      exampleView: Glossa.QueryRowView,

      // Do not perform any of the normal key event handling for this collection view;
      // just let the event pass up the responder chain
      keyDown: function() {
        return NO;
      }
    })
  })

});

Glossa.resultsView = SC.View.design({
  childViews: 'buttons scroll'.w(),

  buttons: SC.View.design({
    layout: { top: 10, height: 32 },
    classNames: 'gray-bottom-border'.w(),
    childViews: 'saveButton'.w(),

    saveButton: SC.ButtonView.design({
      controlSize: SC.REGULAR_CONTROL_SIZE,
      layout: { left: 10, width: 80, height: 24 },
      title: 'Save',
      action: 'myMethod',
      target: 'MyApp.Controller'
    })
  }),

  scroll: SC.ScrollView.design({
    layout: { top: 45, bottom: 10 },
    contentView: SC.ListView.design({
      contentBinding: 'Glossa.searchResultsArrayController.arrangedObjects',
      contentValueKey: 'line',
      showAlternatingRows: YES,
      exampleView: SC.ListItemView.design({
        escapeHTML: NO
      })
    })
  })
});


