#= require ./corpus_info

###* @jsx React.DOM ###

window.Start = React.createClass
  propTypes:
    corpus: React.PropTypes.object.isRequired

  render: ->
    `<span><CorpusInfo
              corpusName={this.props.corpus.name}
              corpusLogoUrl={this.props.corpus.logo} /></span>`