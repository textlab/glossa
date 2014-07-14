#= require ../../../statechart
#= require rglossa/react/models/corpus
#= require ./language_select
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
    statechart: React.PropTypes.object.isRequired
    corpus: React.PropTypes.object.isRequired
    searchQuery: React.PropTypes.string.isRequired
    handleQueryChanged: React.PropTypes.func.isRequired
    handleSearch: React.PropTypes.func.isRequired

  getInitialState: ->
    statechart: new Statechart(
      'CwbSearchInputs', root, (sc) => @setState(statechart: sc))

  showSimple: (e) ->
    e.preventDefault()
    @state.statechart.handleAction('showSimple')

  showMultiword: (e) ->
    e.preventDefault()
    @state.statechart.handleAction('showMultiword')

  showRegex: (e) ->
    e.preventDefault()
    @state.statechart.handleAction('showRegex')

  languageSelect: ->
    if corpusNs.isMultilingual(@props.corpus)
      `<LanguageSelect corpus={this.props.corpus} />`
    else
      null

  render: ->
    {corpus, searchQuery, handleQueryChanged, handleSearch} = @props
    if @state.statechart.pathContains('simple')
      `<span>
        <div className="row-fluid search-input-links">
          <b>Simple</b>&nbsp;|&nbsp;
          <a href="" title="Search for grammatical categories etc." onClick={this.showMultiword}>Extended</a>&nbsp;|&nbsp;
          <a href="" title="Regular expressions" onClick={this.showRegex}>Regexp</a>
        </div>
        {this.languageSelect()}
        <CwbSimpleInput searchQuery={searchQuery} handleQueryChanged={handleQueryChanged} handleSearch={handleSearch} />
      </span>`

    else if @state.statechart.pathContains('multiword')
      `<span>
        <div className="row-fluid search-input-links">
          <a href="" title="Simple search box" onClick={this.showSimple}>Simple</a>&nbsp;|&nbsp;
          <b>Extended</b>&nbsp;|&nbsp;
          <a href="" title="Regular expressions" onClick={this.showRegex}>Regexp</a>
        </div>
        {this.languageSelect()}
        <CwbMultiwordInput
          searchQuery={searchQuery}
          corpus={corpus}
          handleQueryChanged={handleQueryChanged} handleSearch={handleSearch} />
      </span>`

    else
      `<span>
        <div className="row-fluid search-input-links">
          <a href="" title="Simple search box" onClick={this.showSimple}>Simple</a>&nbsp;|&nbsp;
          <a href="" title="Search for grammatical categories etc." onClick={this.showMultiword}>Extended</a>&nbsp;|&nbsp;
          <b>Regexp</b>
        </div>
        {this.languageSelect()}
        <CwbRegexInput searchQuery={searchQuery} handleQueryChanged={handleQueryChanged} handleSearch={handleSearch} />
      </span>`
