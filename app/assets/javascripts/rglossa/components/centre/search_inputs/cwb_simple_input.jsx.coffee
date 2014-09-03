###* @jsx React.DOM ###

window.CwbSimpleInput = React.createClass
  propTypes:
    searchQuery: React.PropTypes.object.isRequired
    handleQueryChanged: React.PropTypes.func.isRequired
    handleSearch: React.PropTypes.func.isRequired

  componentDidMount: ->
    @refs.searchfield.getDOMNode().focus()

  displayedQuery: ->
    # Convert the CQP expression into a pure text search phrase
    @props.searchQuery.query.replace(/\[\w+="(.+?)"\]/g, '$1')

  isPhonetic: ->
    @props.searchQuery.query.indexOf('phon=') isnt -1


  handleTextChanged: (e) ->
    # Convert the search phrase to CQP
    if e.target.value is ''
      query = ''
    else
      attr = if @isPhonetic() then 'phon' else 'word'
      terms = for term in e.target.value.split(/\s+/)
        if term is '' then ' ' else "[#{attr}=\"#{term}\"]"
      query = terms.join(' ')

    @props.handleQueryChanged
      lang: @props.searchQuery.lang
      query: query


  handlePhoneticChanged: (e) ->
    query = if e.target.checked
              @props.searchQuery.query.replace(/word=/g, 'phon=')
            else
              @props.searchQuery.query.replace(/phon=/g, 'word=')
    @props.handleQueryChanged
      lang: @props.searchQuery.lang
      query: query

  handleKeyDown: (e) ->
    if e.key is 'Enter'
      e.preventDefault()
      @props.handleSearch()

  render: ->
    `<div className="row-fluid">
      <form className="form-inline span12">
        <div className="span10">
          <input ref="searchfield" type="text" className="span12" value={this.displayedQuery()}
            onChange={this.handleTextChanged} onKeyDown={this.handleKeyDown} />
          {this.props.hasPhoneticForm && <label style={{marginTop: 5}}><input name="phonetic" type="checkbox" style={{marginTop: -3}} checked={this.isPhonetic()} onChange={this.handlePhoneticChanged}/>&nbsp;Phonetic form</label>}
        </div>
      </form>
    </div>`
