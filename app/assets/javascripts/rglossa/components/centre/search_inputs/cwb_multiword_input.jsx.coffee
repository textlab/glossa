#= require rglossa/models/corpus
#= require ./cwb_multiword_term

###* @jsx React.DOM ###

# This will be used to create a unique ID for each query term component.
# React wants a unique key for each component in a sequence, such as the set
# of search inputs in the multiword interface, and it will mess up the text
# in the search boxes when we remove a term from the query if we don't provide this.
# Normally, the items in a list have some kind of database ID that we can use,
# but query terms don't. Also, we cannot just use a hash code created from the
# queryTerm object, since we may have several identical terms in a query.
# Thus, in getInitialState() we create a list (called queryTermIds) containing a
# unique ID number for each term in the initial query (i.e., the
# one provided in the props when this component is mounted), and then we add a newly
# created ID when adding a query term in the multiword interface and remove the
# terms ID from the list when a term is removed. This is the kind of ugly state
# manipulation that React normally saves us from, but in cases like this it seems
# unavoidable...
lastQueryTermId = 0

createTerm = (overrides = {}) ->
  term =
    word:        ''
    pos:         null
    features:    []
    min:         null
    max:         null

    isLemma:    false
    isPhonetic: false
    isStart:    false
    isEnd:      false

  for k, v of overrides
    term[k] = v

  term


window.CwbMultiwordInput = React.createClass
  propTypes:
    showRemoveRow: React.PropTypes.bool.isRequired
    hasHeadwordSearch: React.PropTypes.bool.isRequired
    searchQuery: React.PropTypes.object.isRequired
    corpus: React.PropTypes.object.isRequired
    handleQueryChanged: React.PropTypes.func.isRequired
    handleRemoveRow: React.PropTypes.func.isRequired
    handleSearch: React.PropTypes.func.isRequired

  getInitialState: ->
    queryTerms = @constructQueryTerms(@props.searchQuery)
    queryTermIds = (lastQueryTermId++ for term in queryTerms)

    queryTerms: queryTerms
    queryTermIds: queryTermIds


  componentWillReceiveProps: (nextProps) ->
    @setState(queryTerms: @constructQueryTerms(nextProps.searchQuery))

  handleKeyDown: (e) ->
    if e.key is 'Enter'
      e.preventDefault()
      @props.handleSearch()


  # an interval, e.g. []{1,2}
  intervalRegexp: /\[\]\{(.+?)\}/

  # an attribute/value expression such as [lemma="car" %c] or [(lemma="car" & pos="n")]
  attributeValueRegexp: ///\[\(?
                             ([^"]+?                      # treat quoted strings separately;
                               (?: "[^"]*" [^\]"]*? )*? ) # they may contain right brackets
                             (?:\s+%c)?
                             \)?\]///

  # a quoted string or a single unspecified token
  quotedStringOrEmptyTermRegexp: /".*?"|\[\]/

  splitQuery: (query) ->
    query.match(///#{@intervalRegexp.source}
                  |#{@quotedStringOrEmptyTermRegexp.source}
                  |#{@attributeValueRegexp.source}///g) or ['[]']

  constructQueryTerms: (queryObj) ->
    queryParts = @splitQuery(queryObj.query)

    dq = []
    min = null
    max = null

    queryParts.forEach (item) =>

      if m = item.match(@intervalRegexp)
        [min, max] = @handleIntervalSpecification(m)

      else if m = item.match(@attributeValueRegexp)
        dq.push @handleAttributes(m, min, max)
        min = null
        max = null

      else if m = item.match(@quotedStringOrEmptyTermRegexp)
        word    = item.substring(1, item.length-1)
        isStart = /\.\+$/.test(word)
        isEnd   = /^\.\+/.test(word)

        # Remove wildcard symbols at the beginning or end since they should not be
        # shown in the text boxes (but as check boxes instead)
        word = word.replace(/^(?:\.\+)?(.+?)/, "$1").replace(/(.+?)(?:\.\+)?$/, "$1")

        term = createTerm(word: word, min: min, max: max, isStart: isStart, isEnd: isEnd)
        dq.push(term)

        min = null
        max = null

    dq


  handleIntervalSpecification: (m) ->
    intervalText = m[1]
    min = max = null

    m2 = intervalText.match(/(\d+),/)
    min = m2[1] if m2

    m2 = intervalText.match(/,(\d+)/)
    max = m2[1] if m2

    [min, max]


  handleAttributes: (m, min, max) ->
    attributes = m[1].split(/\s*&\s*/)
    term = createTerm(min: min, max: max)

    for attr in attributes
      m2 = attr.match(/\(?(\S+)\s*=\s*"(\S+)"/)
      posAttr = corpusNs.getPOSAttribute(@props.corpus)

      switch m2[1]
        when 'word', 'lemma', 'phon'
          term.word = m2[2]
          term.isLemma = m2[1] is 'lemma'
          term.isPhonetic = m2[1] is 'phon'
          term.isStart = /\.\+$/.test(m2[2])
          term.isEnd = /^\.\+/.test(m2[2])
        when posAttr then term.pos = m2[2]
        else term.features.push(attr: m2[1], value: m2[2])

      # Remove any .+ at the beginning and/or end of the displayed form
      term.word = term.word.replace(/^(?:\.\+)?(.+?)/, "$1").replace(/(.+?)(?:\.\+)?$/, "$1")
    term


  handleTermChanged: (term, termIndex) ->
    queryTerms = @state.queryTerms
    queryTerms[termIndex] = term
    @props.handleQueryChanged
      lang: @props.searchQuery.lang
      query: @constructCQPQuery(queryTerms)
      headwordSearch: @props.searchQuery.headwordSearch


  handleHeadwordSearchChanged: (e) ->
    @props.handleQueryChanged
      lang: @props.searchQuery.lang
      query: @constructCQPQuery(@state.queryTerms)
      headwordSearch: e.target.checked


  handleAddTerm: ->
    queryTerms = @state.queryTerms
    queryTerms.push(createTerm())
    queryTermIds = @state.queryTermIds
    queryTermIds.push(lastQueryTermId++)

    @setState(queryTermIds: queryTermIds)
    @props.handleQueryChanged
      lang: @props.searchQuery.lang
      query: @constructCQPQuery(queryTerms)
      headwordSearch: @props.searchQuery.headwordSearch


  handleRemoveTerm: (termIndex) ->
    queryTerms = @state.queryTerms
    queryTerms.splice(termIndex, 1)
    queryTermIds = @state.queryTermIds
    queryTermIds.splice(termIndex, 1)

    @setState(queryTermIds: queryTermIds)
    @props.handleQueryChanged
      lang: @props.searchQuery.lang
      query: @constructCQPQuery(queryTerms)
      headwordSearch: @props.searchQuery.headwordSearch


  constructCQPQuery: (queryTerms) ->
    parts = for term in queryTerms
      {min, max, word, isLemma, isPhonetic, isStart, isEnd, pos, features} = term
      attrs = []

      if word
        attr = if isLemma then 'lemma' else if isPhonetic then 'phon' else 'word'
        word = "#{word}.+" if isStart
        word = ".+#{word}" if isEnd
        word = "(#{attr}=\"#{word}\" %c)"
        attrs.push(word)

      if pos
        posAttr = corpusNs.getPOSAttribute(@props.corpus)
        posStr = "#{posAttr}=\"#{pos}\""
        attrs.push(posStr)

      for feature in features
        f = "#{feature.attr}=\"#{feature.value}\""
        attrs.push(f)

      str = '[' + attrs.join(' & ') + ']'

      if min or max
        str = "[]{#{min ? 0},#{max ? ''}} " + str

      str

    parts.join(' ')


  render: ->
    queryTerms = @state.queryTerms
    lastIndex = queryTerms.length - 1

    `<div className="row-fluid multiword-container">
      <form className="form-inline multiword-search-form">
        <div style={{display: 'table'}}>
          <div style={{display: 'table-row'}}>
          {queryTerms.map(function(term, index) {
            return (
              <CwbMultiwordTerm
                key={this.state.queryTermIds[index]}
                showRemoveRow={this.props.showRemoveRow}
                hasPhoneticForm={this.props.corpus.has_phonetic}
                term={term}
                termIndex={index}
                queryHasSingleTerm={this.state.queryTerms.length === 1}
                isFirst={index === 0}
                isLast={index === lastIndex}
                tags={corpusNs.getTags(this.props.corpus)}
                handleRemoveRow={this.props.handleRemoveRow}
                handleKeyDown={this.handleKeyDown}
                handleTermChanged={this.handleTermChanged}
                handleAddTerm={this.handleAddTerm}
                handleRemoveTerm={this.handleRemoveTerm} />
            )
          }, this)}
          </div>
          {this.props.hasHeadwordSearch && <label style={{lineHeight: '13px'}}><input type="checkbox" value="1" checked={this.props.searchQuery.headwordSearch} onChange={this.handleHeadwordSearchChanged} id="headword_search" name="headword_search" style={{margin: '0px'}} /> Headword search</label>}
        </div>
      </form>
    </div>`
