#= require rglossa/utils
#= require ../search_inputs/cwb_search_inputs
#= require ./results_toolbar
#= require ./cwb_results_table
#= require dialog
#= require ./geo_distribution_map

###* @jsx React.DOM ###

window.ResultsMain = React.createClass
  propTypes:
    store: React.PropTypes.object.isRequired
    statechart: React.PropTypes.object.isRequired
    results: React.PropTypes.object
    currentResultPageNo: React.PropTypes.number.isRequired
    corpus: React.PropTypes.object.isRequired
    searchQueries: React.PropTypes.array.isRequired
    handleQueryChanged: React.PropTypes.func.isRequired
    sortBy: React.PropTypes.string.isRequired
    handleSortByChanged: React.PropTypes.func.isRequired
    maxHits: React.PropTypes.number
    handleSearch: React.PropTypes.func.isRequired
    handleAddLanguage: React.PropTypes.func.isRequired
    handleAddPhrase: React.PropTypes.func.isRequired

  getInitialState: ->
    frequencies: null
    geoDistribution: null

  showFrequencies: (attribute, e) ->
    e.preventDefault()

    # Prevents the dialog box from showing stale results and instead
      # makes it show a 'loading' message while we fetch new frequencies
    @setState(frequencies: null)

    $.ajax(
      # TODO: Support other search engines besides CWB
      url: 'r/search_engines/cwb/query_freq'
      method: 'POST'
      data: JSON.stringify
        corpus: @props.corpus.short_name
        query: @props.searchQueries
        attribute: attribute
      dataType: 'json'
      contentType: 'application/json'
    ).done (res) =>
      @setState(frequencies: res.pairs)

    @refs.frequencies.show()


  frequencyList: ->
    if @state.frequencies
      @state.frequencies.map (pair) ->
        `<tr><td>{pair.form}</td><td>{pair.freq}</td></tr>`
    else
      `<td colSpan="2">Loading...</td>`


  showMap: (e) ->
    e.preventDefault()

    # Prevents the dialog box from showing stale results and instead
    # makes it show a 'loading' message while we fetch the new geo-distribution results
    @setState(geoDistribution: null)

    $.getJSON("search_engines/speech_cwb_searches/#{@props.results.id}/geo_distr").then (res) =>
      @setState(geoDistribution: res)

    @refs.distrMap.show()


  render: ->
    {store, statechart, results, currentResultPageNo, corpus, searchQueries, handleQueryChanged,
      sortBy, handleSortByChanged, handleAddLanguage, handleAddPhrase,
      maxHits, handleSearch} = @props
    resultPage = results?.pages[currentResultPageNo]

    # Select components based on the search engine name,
    # e.g. CwbSearchInputs and CwbResultsTable
    searchEngine = corpus.search_engine or 'cwb'
    capSearchEngine = rglossaUtils.capitalize(searchEngine)
    searchInputs = window["#{capSearchEngine}SearchInputs"]
    resultTable = window["#{capSearchEngine}ResultsTable"]

    `<span>
      <searchInputs
        store={store}
        corpus={corpus}
        statechart={statechart}
        searchQueries={searchQueries}
        handleQueryChanged={handleQueryChanged}
        maxHits={maxHits}
        handleSearch={handleSearch}
        handleAddLanguage={handleAddLanguage}
        handleAddPhrase={handleAddPhrase} />
      <ResultsToolbar
        store={store}
        statechart={statechart}
        corpus={corpus}
        results={results}
        currentResultPageNo={currentResultPageNo}
        sortBy={sortBy}
        handleSortByChanged={handleSortByChanged}
        showFrequencies={this.showFrequencies}
        showMap={this.showMap} />
      <resultTable
        resultPage={resultPage}
        corpus={corpus} />
      <Dialog ref="frequencies" title="Frequencies">
        <table className="table table-striped table-condensed">
          <thead>
            <td>Form</td><td>Frequency</td>
          </thead>
          <tbody>
            {this.frequencyList()}
          </tbody>
        </table>
      </Dialog>
      <Dialog ref="distrMap" extraClassName="distr-map" title="Geographical distribution of results">
        <GeoDistributionMap data={this.state.geoDistribution} />
      </Dialog>
    </span>`
