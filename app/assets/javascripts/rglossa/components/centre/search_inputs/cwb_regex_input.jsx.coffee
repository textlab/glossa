###* @jsx React.DOM ###

window.CwbRegexInput = React.createClass
  propTypes:
    searchQuery: React.PropTypes.object.isRequired
    handleQueryChanged: React.PropTypes.func.isRequired
    handleSearch: React.PropTypes.func.isRequired

  componentDidMount: ->
    @refs.searchfield.getDOMNode().focus()

  handleTextChanged: (e) ->
    @props.handleQueryChanged
      lang: @props.searchQuery.lang
      query: e.target.value

  displayedQuery: ->
    # Just take the CQP expression
    @props.searchQuery.query

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
