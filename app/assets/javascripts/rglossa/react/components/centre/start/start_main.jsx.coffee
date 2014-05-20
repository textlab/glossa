#= require ./corpus_info
#= require ../shared/search_inputs

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
      <SearchInputs
        statechart={this.props.statechart} />
    </span>`