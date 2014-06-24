#= require rglossa/react/utils
#= require ./corpus_info
#= require ../search_inputs/cwb_search_inputs

###* @jsx React.DOM ###

window.StartMain = React.createClass
  propTypes:
    store: React.PropTypes.object.isRequired
    statechart: React.PropTypes.object.isRequired
    corpus: React.PropTypes.object.isRequired
    query: React.PropTypes.string.isRequired
    handleQueryChanged: React.PropTypes.func.isRequired
    maxHits: React.PropTypes.number.isRequired

  render: ->
    {store, statechart, corpus, query, handleQueryChanged, maxHits, handleMaxHitsChanged} = @props
    {name, logo} = corpus

    # Select a component based on the search engine name, e.g. CwbSearchInputs
    searchEngine = corpus.search_engine or 'cwb'
    searchInputs = window["#{capitalize(searchEngine)}SearchInputs"]

    `<span>
      <CorpusInfo
        corpusName={name}
        corpusLogoUrl={logo} />
      <searchInputs
        store={store}
        statechart={statechart}
        corpus={corpus}
        query={query}
        handleQueryChanged={handleQueryChanged}
        maxHits={maxHits} />
    </span>`