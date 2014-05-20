#= require ./corpus_info
#= require ../search_inputs/cwb_search_inputs

###* @jsx React.DOM ###

window.StartMain = React.createClass
  propTypes:
    statechart: React.PropTypes.object.isRequired
    corpus: React.PropTypes.object.isRequired

  render: ->
    {name, logo} = @props.corpus
    `<span>
      <CorpusInfo
        corpusName={name}
        corpusLogoUrl={logo} />
      <CwbSearchInputs />
    </span>`