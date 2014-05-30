#= require ./corpus_info
#= require ../search_inputs/cwb_search_inputs

###* @jsx React.DOM ###

window.StartMain = React.createClass
  propTypes:
    statechart: React.PropTypes.object.isRequired
    corpus: React.PropTypes.object.isRequired

  render: ->
    corpus = @props.corpus
    {name, logo} = corpus
    `<span>
      <CorpusInfo
        corpusName={name}
        corpusLogoUrl={logo} />
      <CwbSearchInputs corpus={corpus} />
    </span>`