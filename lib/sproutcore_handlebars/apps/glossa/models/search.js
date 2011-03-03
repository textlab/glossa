// ==========================================================================
// Project:   Glossa.Search
// Copyright: ©2010 The Text Laboratory, University of Oslo
// ==========================================================================
/*globals Glossa */

Glossa.QueryArray = SC.RecordAttribute.extend(SC.Array, {
});

Glossa.Query = SC.Object.extend({
  corpus: '',
  terms: []
});

SC.RecordAttribute.registerTransform(Glossa.QueryArray, {
  to: function(str) {
    var ary = eval(str);
    var newAry = [];
    ary.forEach(function(elm) {
      newAry.push(Glossa.Query.create({corpus: elm.corpus, terms: elm.terms}));
    });
    return newAry;
  },

  from: function(query_ary) {
    var queries = [];
    query_ary.forEach(function(query) {
      queries.push({corpus: query.corpus, terms: query.terms});
    });
    return queries;
  }
});

/** @class

  (Document your Model here)

  @extends SC.Record
  @version 0.1
*/
Glossa.Search = SC.Record.extend(
/** @scope Glossa.Search.prototype */ {

  queries: SC.Record.attr(Glossa.QueryArray)

}) ;

