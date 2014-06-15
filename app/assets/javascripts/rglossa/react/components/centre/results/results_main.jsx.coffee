###* @jsx React.DOM ###

window.ResultsMain = React.createClass
  propTypes:
    statechart: React.PropTypes.object.isRequired
    results: React.PropTypes.array.isRequired

  render: ->
    `<span>{this.props.results.length}</span>`