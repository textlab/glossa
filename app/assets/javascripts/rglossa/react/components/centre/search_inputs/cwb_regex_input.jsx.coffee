###* @jsx React.DOM ###

window.CwbRegexInput = React.createClass
  propTypes:
    query: React.PropTypes.string.isRequired
    handleQueryChanged: React.PropTypes.func.isRequired
    handleSearch: React.PropTypes.func.isRequired

  handleTextChange: (e) ->
    @props.handleQueryChanged(e.target.value)

  render: ->
    `<div className="row-fluid">
      <form className="form-inline span12">
        <div className="input-append span10">
          <input type="text" className="searchfield span12" value={this.props.query} onChange={this.handleTextChange} />
          <button type="button" className="btn btn-success" onClick={this.props.handleSearch}>Search</button>
        </div>
      </form>
    </div>`
