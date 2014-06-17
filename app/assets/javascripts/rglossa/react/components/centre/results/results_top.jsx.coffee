#= require ./num_hits

###* @jsx React.DOM ###

window.ResultsTop = React.createClass
  propTypes:
    results: React.PropTypes.object.isRequired
    corpus: React.PropTypes.object.isRequired

  render: ->
    `<NumHits results={this.props.results} corpus={this.props.corpus} />`