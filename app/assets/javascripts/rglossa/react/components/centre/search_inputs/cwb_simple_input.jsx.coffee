###* @jsx React.DOM ###

window.CwbSimpleInput = React.createClass
  propTypes:
    searchQuery: React.PropTypes.object.isRequired
    handleQueryChanged: React.PropTypes.func.isRequired
    handleSearch: React.PropTypes.func.isRequired

  componentDidMount: ->
    @refs.searchfield.getDOMNode().focus()

  displayedQuery: ->
    # Take the CQP expression and just remove quotes
    @props.searchQuery.query.replace(/"/g, '')

  handleTextChanged: (e) ->
    # Wrap each search term in quotes
    query = ("\"#{term}\"" for term in e.target.value.split(/\s+/)).join(' ')
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
        </div>
      </form>
    </div>`
