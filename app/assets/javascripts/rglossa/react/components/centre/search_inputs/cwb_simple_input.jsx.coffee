###* @jsx React.DOM ###

window.CwbSimpleInput = React.createClass
  propTypes:
    query: React.PropTypes.string.isRequired
    handleQueryChanged: React.PropTypes.func.isRequired
    handleSearch: React.PropTypes.func.isRequired

  displayedQuery: ->
    # Take the CQP expression and just remove quotes
    @props.query.replace(/"/g, '')

  handleTextChanged: (e) ->
    # Wrap each search term in quotes
    query = ("\"#{term}\"" for term in e.target.value.split(/\s+/)).join(' ')
    @props.handleQueryChanged(query)

  handleKeyDown: (e) ->
    if e.key is 'Enter'
      e.preventDefault()
      @props.handleSearch()

  render: ->
    `<div className="row-fluid">
      <form className="form-inline span12">
        <div className="input-append span10">
          <input type="text" className="searchfield span12" value={this.displayedQuery()}
            onChange={this.handleTextChanged} onKeyDown={this.handleKeyDown} />
          <button type="button" className="btn btn-success" onClick={this.props.handleSearch}>Search</button>
        </div>
      </form>
    </div>`
