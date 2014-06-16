###* @jsx React.DOM ###

window.ResultsMain = React.createClass
  propTypes:
    statechart: React.PropTypes.object.isRequired
    results: React.PropTypes.array.isRequired
    currentResultPageNo: React.PropTypes.number.isRequired

  render: ->
    `<span>{this.props.currentResultPageNo}</span>`