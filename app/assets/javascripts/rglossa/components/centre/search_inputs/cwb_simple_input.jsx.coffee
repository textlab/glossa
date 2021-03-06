###* @jsx React.DOM ###

window.CwbSimpleInput = React.createClass
  propTypes:
    showRemoveRow: React.PropTypes.bool.isRequired
    hasPhoneticForm: React.PropTypes.bool.isRequired
    hasHeadwordSearch: React.PropTypes.bool.isRequired
    searchQuery: React.PropTypes.object.isRequired
    handleQueryChanged: React.PropTypes.func.isRequired
    handleRemoveRow: React.PropTypes.func.isRequired
    handleSearch: React.PropTypes.func.isRequired

  componentDidMount: ->
    @refs.searchfield.getDOMNode().focus()

  displayedQuery: ->
    # Convert the CQP expression into a pure text search phrase
    query = MainArea.convertToNonHeadwordQuery(@props.searchQuery.query)
    query.replace(/\[\(?\w+="(.*?)"(?:\s+%c)?\)?\]/g, '$1').
          replace(/"([^\s=]+)"/g, '$1').replace(/\s*\[\]\s*/g, " .* ").
          replace(/^\.\*$/, "")

  isPhonetic: ->
    @props.searchQuery.query.indexOf('phon=') isnt -1


  handleTextChanged: (e) ->
    # Convert the search phrase to CQP
    if e.target.value is '' and not @isPhonetic()
      query = ''
    else
      attr = if @isPhonetic() then 'phon' else 'word'
      # Surround every Chinese character by space when constructing a cqp query,
      # to treat it as if it was an individual word:
      chineseCharsRange = '[\u4E00-\u9FFF\u3400-\u4DFF\uF900-\uFAFF]'
      terms = for term in e.target.value.replace(///(#{chineseCharsRange})///g, ' $1 ').split(/\s/)
        if term is '' then '' else "[#{attr}=\"#{term}\" %c]"
      query = terms.join(' ').replace(///\s(\[\w+="#{chineseCharsRange}"(?:\s+%c)?\])\s///g, "$1") ||
              "[#{attr}=\".*\" %c]"

    @props.handleQueryChanged
      lang: @props.searchQuery.lang
      query: query
      headwordSearch: @props.searchQuery.headwordSearch

  handlePhoneticChanged: (e) ->
    query = if e.target.checked
              @props.searchQuery.query.replace(/word=/g, 'phon=') || '[phon=".*" %c]'
            else
              @props.searchQuery.query.replace(/phon=/g, 'word=')
    @props.handleQueryChanged
      lang: @props.searchQuery.lang
      query: MainArea.convertToNonHeadwordQuery(query)
      headwordSearch: @props.searchQuery.headwordSearch

  handleHeadwordSearchChanged: (e) ->
    @props.handleQueryChanged
      lang: @props.searchQuery.lang
      query: @props.searchQuery.query
      headwordSearch: e.target.checked

  handleKeyDown: (e) ->
    if e.key is 'Enter'
      e.preventDefault()
      @props.handleSearch(searchInput: 'simple')

  render: ->
    `<div className="row-fluid">
      <form className="form-inline span12">
        <div className="span10">
          {this.props.showRemoveRow ? <button className="btn btn-small" title="Remove row" style={{cursor: 'pointer', margin: '0 5px 0 -35px'}} onClick={this.props.handleRemoveRow}><i className="icon-remove"></i></button> : null}
          <input ref="searchfield" type="text" className="span10" value={this.displayedQuery()}
              onChange={this.handleTextChanged} onClick={this.handleTextChanged} onKeyDown={this.handleKeyDown} />
          <div>
            {this.props.hasPhoneticForm && <label style={{marginTop: 5}}><input name="phonetic" type="checkbox" style={{marginTop: -3}} checked={this.isPhonetic()} onClick={this.handlePhoneticChanged} />&nbsp;Phonetic form</label>}
            {this.props.hasHeadwordSearch && <label style={{lineHeight: '13px'}}><input type="checkbox" value="1" checked={this.props.searchQuery.headwordSearch} onChange={this.handleHeadwordSearchChanged} id="headword_search" name="headword_search" style={{margin: '0px'}} /> Headword search</label>}
          </div>
        </div>
      </form>
    </div>`
