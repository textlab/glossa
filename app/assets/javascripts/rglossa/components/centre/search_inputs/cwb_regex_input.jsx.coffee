###* @jsx React.DOM ###

window.CwbRegexInput = React.createClass
  propTypes:
    showRemoveRow: React.PropTypes.bool.isRequired
    searchQuery: React.PropTypes.object.isRequired
    handleQueryChanged: React.PropTypes.func.isRequired
    handleRemoveRow: React.PropTypes.func.isRequired
    handleSearch: React.PropTypes.func.isRequired

  componentDidMount: ->
    @refs.searchfield.getDOMNode().focus()

  handleTextChanged: (e) ->
    @props.handleQueryChanged
      lang: @props.searchQuery.lang
      query: MainArea.convertToNonHeadwordQuery(e.target.value)
      headwordSearch: MainArea.convertToHeadwordQuery(
                        MainArea.convertToNonHeadwordQuery(e.target.value)) == e.target.value

  displayedQuery: ->
    # Just take the CQP expression
    @props.searchQuery.query

  handleKeyDown: (e) ->
    if e.key is 'Enter'
      e.preventDefault()
      @props.handleSearch(searchInput: 'regex')

  render: ->
    `<div className="row-fluid">
      <form className="form-inline span12">
        <div className="span10">
          {this.props.showRemoveRow ? <button className="btn btn-small" title="Remove row" style={{cursor: 'pointer', margin: '0 5px 0 -35px'}} onClick={this.props.handleRemoveRow}><i className="icon-remove"></i></button> : null}
          <input ref="searchfield" type="text" className="span10" value={this.displayedQuery()}
            onChange={this.handleTextChanged} onKeyDown={this.handleKeyDown} />
        </div>
      </form>
    </div>`
