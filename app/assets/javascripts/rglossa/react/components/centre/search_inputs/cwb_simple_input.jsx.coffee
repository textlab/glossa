###* @jsx React.DOM ###

window.CwbSimpleInput = React.createClass
  propTypes:
    query: React.PropTypes.string.isRequired
    handleQueryChanged: React.PropTypes.func.isRequired

  displayedQuery: ->
    # Take the CQP expression and just remove quotes
    @props.query.replace(/"/g, '')

  handleTextChange: (e) ->
    # Wrap each search term in quotes
    query = ("\"#{term}\"" for term in e.target.value.split(/\s+/)).join(' ')
    @props.handleQueryChanged(query)

  handleSearch: (e) ->
    console.log('search')

  render: ->
    `<div className="row-fluid">
      <form className="form-inline span12">
        <div className="input-append span10">
          <input type="text" className="searchfield span12" value={this.displayedQuery()} onChange={this.handleTextChange} />
          <button type="button" className="btn btn-success" onClick={this.handleSearch}>Search</button>
        </div>
      </form>
    </div>`
