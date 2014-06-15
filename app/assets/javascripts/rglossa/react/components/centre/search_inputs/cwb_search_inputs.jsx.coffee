#= require ../../../statechart
#= require ./cwb_simple_input
#= require ./cwb_multiword_input
#= require ./cwb_regex_input

###* @jsx React.DOM ###

# Search inputs for corpora encoded with the IMS Corpus Workbench

root =
  initialSubstate: 'simple'
  substates:
    simple: {}
    multiword: {}
    regex: {}
  actions:
    showSimple: -> @transitionTo('simple')
    showMultiword: -> @transitionTo('multiword')
    showRegex: -> @transitionTo('regex')

window.CwbSearchInputs = React.createClass
  propTypes:
    store: React.PropTypes.object.isRequired
    corpus: React.PropTypes.object.isRequired
    statechart: React.PropTypes.object.isRequired

  getInitialState: ->
    statechart: new Statechart(
      'CwbSearchInputs', root, (sc) => @setState(statechart: sc))
    query: ''

  showSimple: (e) ->
    e.preventDefault()
    @state.statechart.handleAction('showSimple')

  showMultiword: (e) ->
    e.preventDefault()
    @state.statechart.handleAction('showMultiword')

  showRegex: (e) ->
    e.preventDefault()
    @state.statechart.handleAction('showRegex')

  handleQueryChanged: (query) ->
    @setState(query: query)

  handleSearch: ->
    searchEngine = @props.corpus.search_engine ?= 'cwb'
    url = "search_engines/#{searchEngine}_searches"
    query =
      query: @state.query
      corpusShortName: @props.corpus.short_name

    $.ajax(
      url: url
      method: 'POST'
      data: JSON.stringify
        queries: [query]
        max_hits: 2000
      dataType: 'json'
      contentType: 'application/json'
    ).then (res) =>
      searchModel = "#{searchEngine}_search"
      id = res[searchModel].id
      @props.store.setData('searches', id, res[searchModel])
      @props.statechart.handleAction('showResults', id)

  render: ->
    if @state.statechart.pathContains('simple')
      `<span>
        <div className="row-fluid search-input-links">
          <b>Simple</b>&nbsp;|&nbsp;
          <a href="" title="Search for grammatical categories etc." onClick={this.showMultiword}>Extended</a>&nbsp;|&nbsp;
          <a href="" title="Regular expressions" onClick={this.showRegex}>Regexp</a>
        </div>
        <CwbSimpleInput query={this.state.query} handleQueryChanged={this.handleQueryChanged} handleSearch={this.handleSearch} />
      </span>`

    else if @state.statechart.pathContains('multiword')
      `<span>
        <div className="row-fluid search-input-links">
          <a href="" title="Simple search box" onClick={this.showSimple}>Simple</a>&nbsp;|&nbsp;
          <b>Extended</b>&nbsp;|&nbsp;
          <a href="" title="Regular expressions" onClick={this.showRegex}>Regexp</a>
        </div>
        <CwbMultiwordInput
          query={this.state.query}
          corpus={this.props.corpus}
          handleQueryChanged={this.handleQueryChanged} handleSearch={this.handleSearch} />
      </span>`

    else
      `<span>
        <div className="row-fluid search-input-links">
          <a href="" title="Simple search box" onClick={this.showSimple}>Simple</a>&nbsp;|&nbsp;
          <a href="" title="Search for grammatical categories etc." onClick={this.showMultiword}>Extended</a>&nbsp;|&nbsp;
          <b>Regexp</b>
        </div>
        <CwbRegexInput query={this.state.query} handleQueryChanged={this.handleQueryChanged} handleSearch={this.handleSearch} />
      </span>`
