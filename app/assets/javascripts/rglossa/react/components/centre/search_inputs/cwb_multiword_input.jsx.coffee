#= require ./cwb_multiword_term

###* @jsx React.DOM ###

createTerm = (overrides = {}) ->
  term =
    word:     ''
    pos:      null
    features: []
    min:      null
    max:      null

    isLemma: false
    isStart: false
    isEnd:   false

  for k, v of overrides
    term[k] = v

  term


window.CwbMultiwordInput = React.createClass
  propTypes:
    query: React.PropTypes.string.isRequired
    corpus: React.PropTypes.object.isRequired
    handleQueryChanged: React.PropTypes.func.isRequired
    handleSearch: React.PropTypes.func.isRequired

  getInitialState: ->
    queryTerms: @constructQueryTerms(@props.query)

  componentWillReceiveProps: (nextProps) ->
    @setState(queryTerms: @constructQueryTerms(nextProps.query))

  constructQueryTerms: (query) ->
    queryParts = @splitQuery(query)

    dq = []
    min = null
    max = null

    queryParts.forEach (item) =>
      if m = item.match(/\[\]\{(.+?)\}/)
        [min, max] = @handleIntervalSpecification(m)
      else if m = item.match(/\[(.+?)\]/)
        dq.push @handleAttributes(m, min, max)
        min = null
        max = null
      else
        word    = item.substring(1, item.length-1)
        isStart = /\.\+$/.test(word)
        isEnd   = /^\.\+/.test(word)
        word = word.replace(/^(?:\.\+)?(.+?)/, "$1").replace(/(.+?)(?:\.\+)?$/, "$1")

        term = createTerm(word: word, min: min, max: max, isStart: isStart, isEnd: isEnd)
        dq.push(term)

        min = null
        max = null

    dq


  splitQuery: (query) ->
    query.match(/\[\]\{(.+?)\}|".*?"|\[[^\]]+?\]/g) or ['']


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
      switch m2[1]
        when 'word', 'lemma'
          term.word = m2[2]
          term.isLemma = m2[1] is 'lemma'
          term.isStart = /\.\+$/.test(m2[2])
          term.isEnd = /^\.\+/.test(m2[2])
        when 'pos' then term[@.props.posAttr] = m2[2]
        else term.features.push(attr: m2[1], value: m2[2])

      # Remove any .+ at the beginning and/or end of the displayed form
      term.word = term.word.replace(/^(?:\.\+)?(.+?)/, "$1").replace(/(.+?)(?:\.\+)?$/, "$1")
    term


  handleTermChanged: (term, termIndex) ->
    queryTerms = @state.queryTerms
    queryTerms[termIndex] = term
    @props.handleQueryChanged(@constructCQPQuery(queryTerms))


  handleAddTerm: ->
    queryTerms = @state.queryTerms
    queryTerms.push(createTerm())
    @props.handleQueryChanged(@constructCQPQuery(queryTerms))


  handleRemoveTerm: (termIndex) ->
    queryTerms = @state.queryTerms
    queryTerms.splice(termIndex, 1)
    @props.handleQueryChanged(@constructCQPQuery(queryTerms))


  handleAddPos: (pos, termIndex) ->
    queryTerms = @state.queryTerms
    queryTerms[termIndex].pos = pos
    @props.handleQueryChanged(@constructCQPQuery(queryTerms))


  handleAddFeature: (option, feature, pos, termIndex) ->
    queryTerms = @state.queryTerms
    queryTerms[termIndex].features.push
      attr: feature.attr
      value: option.value
    @props.handleQueryChanged(@constructCQPQuery(queryTerms))


  constructCQPQuery: (queryTerms) ->
    parts = for term in queryTerms
      {min, max, word, isLemma, isStart, isEnd, pos, features} = term
      attrs = []

      if isLemma or pos or features.length
        if word
          attr = if isLemma then 'lemma' else 'word'
          word = "#{word}.+" if isStart
          word = ".+#{word}" if isEnd
          word = "(#{attr}=\"#{word}\" %c)"
          attrs.push(word)

        if pos
          posAttr = @props.corpus.langs[0].tags?.attr
          pos = "#{posAttr}=\"#{pos.value}\""
          attrs.push(pos)

        for feature in features
          f = "#{feature.attr}=\"#{feature.value}\""
          attrs.push(f)

        str = '[' + attrs.join(' & ') + ']'
      else
        # Only the word attribute is specified, so use a simple string
        word = "#{word}.+" if isStart
        word = ".+#{word}" if isEnd
        str = "\"#{word}\""
      if min or max
        str = "[]{#{min ? ''},#{max ? ''}} " + str

      str

    parts.join(' ')


  render: ->
    queryTerms = @state.queryTerms
    lastIndex = queryTerms.length - 1

    `<div className="row-fluid">
      <form className="form-inline multiword-search-form">
        <div style={{display: 'table'}}>
          <div style={{display: 'table-row'}}>
          {queryTerms.map(function(term, index) {
            return (
              <CwbMultiwordTerm
                term={term}
                termIndex={index}
                queryHasSingleTerm={this.state.queryTerms.length === 1}
                isFirst={index === 0}
                isLast={index === lastIndex}
                tags={this.props.corpus.langs[0].tags}
                handleTermChanged={this.handleTermChanged}
                handleAddTerm={this.handleAddTerm}
                handleRemoveTerm={this.handleRemoveTerm}
                handleAddPos={this.handleAddPos}
                handleAddFeature={this.handleAddFeature} />
            )
          }, this)}
            <div style={{display: 'table-cell'}}>
              <button type="button" className="btn btn-success search" onClick={this.props.handleSearch}>Search</button>
            </div>
          </div>
        </div>
      </form>
    </div>`
