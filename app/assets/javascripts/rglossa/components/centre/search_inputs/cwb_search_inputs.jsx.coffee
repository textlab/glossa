#= require ../../../statechart
#= require rglossa/models/corpus
#= require ./language_select
#= require ./cwb_simple_input
#= require ./cwb_multiword_input
#= require ./cwb_cqp_query_input

###* @jsx React.DOM ###

# Search inputs for corpora encoded with the IMS Corpus Workbench

window.CwbSearchInputs = React.createClass
  propTypes:
    store: React.PropTypes.object.isRequired
    statechart: React.PropTypes.object.isRequired
    initialSearchInput: React.PropTypes.string
    corpus: React.PropTypes.object.isRequired
    searchQueries: React.PropTypes.array.isRequired
    handleQueryChanged: React.PropTypes.func.isRequired
    handleSearch: React.PropTypes.func.isRequired
    handleAddLanguage: React.PropTypes.func.isRequired
    handleAddPhrase: React.PropTypes.func.isRequired
    handleRemoveRow: React.PropTypes.func.isRequired

  getInitialState: ->
    root =
      initialSubstate: @props.initialSearchInput || 'simple'
      substates:
        simple: {}
        multiword: {}
        cqp: {}
      actions:
        showSimple: -> @transitionTo('simple')
        showMultiword: -> @transitionTo('multiword')
        showCqpQuery: -> @transitionTo('cqp')

    statechart: new Statechart(
      'CwbSearchInputs', root, (sc) => @setState(statechart: sc))

  showSimple: (e) ->
    e.preventDefault()
    @state.statechart.handleAction('showSimple')

  showMultiword: (e) ->
    e.preventDefault()
    @state.statechart.handleAction('showMultiword')

  showCqpQuery: (e) ->
    e.preventDefault()
    @state.statechart.handleAction('showCqpQuery')

  languageSelect: (query) ->
    if @isMultilingual()
      `<LanguageSelect
        corpus={this.props.corpus}
        selectedValue={query.lang} />`

  languageAddButton: ->
    if @isMultilingual()
      `<button className="btn" style={{marginLeft: 20}} onClick={this.props.handleAddLanguage}>Add language</button>`

  searchButton: ->
    marginLeft = if @isMultilingual() then 80 else 40  # adjust position relative to the language select
    `<button type="button" className="btn btn-success"
        style={{marginLeft: marginLeft}} onClick={this.props.handleSearch}>Search</button>`

  addPhraseButton: ->
    unless @props.searchQueries[0].headwordSearch or @isMultilingual()
      `<button className="btn add-phrase-btn" onClick={this.props.handleAddPhrase}>Or...</button>`

  chineseIME: ->
    if corpusNs.getLanguage(@props.corpus, 'zh')
      `<label style={{lineHeight: '13px'}}>
        <input type="checkbox" value="1" id="ime_check" name="ime_check" style={{margin: '0px'}} /> Enable Chinese Input Method
      </label>`

  updateChineseIME: ->
    $("input[type='text']").chineseInput
      debug: false,
      input:
        initial: 'simplified',
        allowChange: false,
      allowHide: true,
      active: $('#ime_check').prop('checked')

  componentDidMount: ->
    @updateChineseIME()

  componentDidUpdate: ->
    $("input[type='text']").unbind()
    @updateChineseIME()

  enabled: (path) ->
    if path == "simple"
      @props.searchQueries.every (query) ->
        MainArea.convertToNonHeadwordQuery(query.query).
                 match(///^\s*
                         ( \[ \(? (?:word|phon) = "[^"]*" (?: \s+ %c )? \)? \] \s*
                         | "[^"]*" \s* | \[\] \s*
                         )*$///)
    else
      true

  searchInput: (name, title, onClick, path) ->
    if @state.statechart.pathContains(path)
      `<b>{name}</b>`
    else if not @enabled(path)
      name
    else
      `<a href="" title={title} onClick={onClick}>{name}</a>`

  searchInputLinks: ->
    `<div className="row-fluid search-input-links">
      {this.searchInput("Simple", "Simple search box", this.showSimple, "simple")}&nbsp;|&nbsp;
      {this.searchInput("Extended", "Search for grammatical categories etc.", this.showMultiword, "multiword")}&nbsp;|&nbsp;
      {this.searchInput("CQP query", "The Corpus Workbench query language", this.showCqpQuery, "cqp")}
      {this.searchButton()}
      {this.languageAddButton()}
    </div>`

  isMultilingual: ->
    corpusNs.isMultilingual(@props.corpus)

  render: ->
    {corpus, searchQueries, handleQueryChanged, handleSearch} = @props

    if @state.statechart.pathContains('simple')
      component = CwbSimpleInput
    else if @state.statechart.pathContains('multiword')
      component = CwbMultiwordInput
    else if @state.statechart.pathContains('cqp')
      component = CwbCqpQueryInput

    `<span>
      {this.chineseIME()}
      {this.searchInputLinks()}
      {searchQueries.map(function(searchQuery, index) {
        return ([
          this.languageSelect(searchQuery),
          React.createElement(component, {
            showRemoveRow: searchQueries.length > 1,
            hasPhoneticForm: corpus.has_phonetic,
            hasHeadwordSearch: !!corpus.headword_search && searchQueries.length == 1,
            searchQuery: searchQuery,
            corpus: corpus,
            handleQueryChanged: handleQueryChanged.bind(null, index),
            handleRemoveRow: this.props.handleRemoveRow.bind(null, index),
            handleSearch: handleSearch
          })
        ])
      }.bind(this))}
      {this.addPhraseButton()}
    </span>`
