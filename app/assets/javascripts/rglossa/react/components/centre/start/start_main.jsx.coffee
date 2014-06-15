#= require ./corpus_info
#= require ../search_inputs/cwb_search_inputs

###* @jsx React.DOM ###

window.StartMain = React.createClass
  propTypes:
    store: React.PropTypes.object.isRequired
    statechart: React.PropTypes.object.isRequired
    corpus: React.PropTypes.object.isRequired

  render: ->
    {store, statechart, corpus} = @props
    {name, logo} = corpus
    `<span>
      <CorpusInfo
        corpusName={name}
        corpusLogoUrl={logo} />
      <CwbSearchInputs
        store={store}
        statechart={statechart}
        corpus={corpus}  />
    </span>`