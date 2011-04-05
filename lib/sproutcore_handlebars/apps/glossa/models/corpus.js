// ==========================================================================
// Project:   Glossa.Corpus
// Copyright: ©2011 The Text Laboratory, University of Oslo
// Author:    Anders Nøklestad (anders.noklestad@iln.uio.no)
// ==========================================================================
/*globals Glossa */

/** @class

  (Document your Model here)

  @extends SC.Record
  @version 0.1
*/
Glossa.Corpus = SC.Record.extend(
/** @scope Glossa.Corpus.prototype */ {

    name: SC.Record.attr(String)

}) ;

Glossa.Corpus.mixin({
    pluralResourcePath: '/corpora'
});
