// ==========================================================================
// Project:   Glossa.Search Fixtures
// Copyright: ©2010 The Text Laboratory, University of Oslo
// ==========================================================================
/*globals Glossa */

sc_require('models/search');

Glossa.Search.FIXTURES = [

  { guid: 1,
    queries: [{
      corpus: 'dickens',
      terms: [
        { min: null, max: null, string: 'a' },
        { min: 1, max: 1, string: 'b' },
        { min: null, max: null, string: 'c' }
      ]
    }]
  }
];
