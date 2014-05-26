#= require ./cwb_multiword_term

###* @jsx React.DOM ###

window.CwbMultiwordInput = React.createClass
  propTypes:
    query: React.PropTypes.string.isRequired
    handleQueryChanged: React.PropTypes.func.isRequired

  displayedQuery: ->
    query = @splitQueryTerms()

    dq = []
    min = null
    max = null

    query.forEach (item) =>
      if m = item.match(/\[\]\{(.+)\}/)
        [min, max] = @handleIntervalSpecification(m)
      else if m = item.match(/\[(.+)\]/)
        dq.push @handleAttributes(m, min, max)
        min = null
        max = null
      else
        word    = item.substring(1, item.length-1)
        isStart = /\.\+$/.test(word)
        isEnd   = /^\.\+/.test(word)
        word = word.replace(/^(?:\.\+)?(.+?)/, "$1").replace(/(.+?)(?:\.\+)?$/, "$1")

        dq.push
          word:     word
          features: []
          min:      min
          max:      max
          isStart:  isStart
          isEnd:    isEnd

        min = null
        max = null

    dq


  splitQueryTerms: ->
    @props.query.match(/\[\]\{(.+)\}|"[^"\s]+"|\[[^\]]+\]/g) or ['']


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
    term =
      min: min
      max: max
      features: []

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


  render: ->
    displayedQuery = @displayedQuery()
    lastIndex = displayedQuery.length - 1

    `<div className="row-fluid">
      <form className="form-inline multiword-search-form">
        <div style={{display: 'table'}}>
          <div style={{display: 'table-row'}}>
          {displayedQuery.map(function(term, index) {
            return (
              <CwbMultiwordTerm
                term={term}
                queryHasSingleTerm={this.props.query.length === 1}
                isFirst={index === 0}
                isLast={index === lastIndex} />
            )
          }, this)}
            <div style={{display: 'table-cell'}}>
              <button type="submit" className="btn btn-success" data-search="">Search</button>
            </div>
          </div>
        </div>
      </form>
    </div>`
