###* @jsx React.DOM ###

window.CwbRegexInput = React.createClass
  propTypes:
    query: React.PropTypes.string.isRequired
    handleQueryChanged: React.PropTypes.func.isRequired
    handleSearch: React.PropTypes.func.isRequired

  componentDidMount: ->
    @refs.searchfield.getDOMNode().focus()

  handleTextChanged: (e) ->
    @props.handleQueryChanged(e.target.value)

  handleKeyDown: (e) ->
    if e.key is 'Enter'
      e.preventDefault()
      @props.handleSearch()

  render: ->
    `<div className="row-fluid">
      <form className="form-inline span12">
        <div className="input-append span10">
          <input ref="searchfield" type="text" className="searchfield span12" value={this.props.query}
            onChange={this.handleTextChanged} onKeyDown={this.handleKeyDown} />
          <button type="button" className="btn btn-success" onClick={this.props.handleSearch}>Search</button>
        </div>
      </form>
    </div>`
