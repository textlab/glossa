###* @jsx React.DOM ###

window.CwbSimpleInput = React.createClass
  getInitialState: ->
    searchText: ''

  displayedQuery: ->
    ''

  handleTextChange: (e) ->
    console.log('text')
    @setState(searchText: e.target.value)

  handleSearch: (e) ->
    console.log('search')

  render: ->
    `<div className="row-fluid">
      <form className="form-inline span12">
        <div className="input-append span10">
          <input type="text" className="searchfield span12" defaultValue={this.state.searchText} onBlur={this.handleTextChange} />
          <button type="button" className="btn btn-success" onClick={this.handleSearch}>Search</button>
        </div>
      </form>
    </div>`
