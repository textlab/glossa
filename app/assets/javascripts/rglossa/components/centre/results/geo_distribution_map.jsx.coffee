###* @jsx React.DOM ###

window.GeoDistributionMap = React.createClass
  propTypes:
    data: React.PropTypes.object.isRequired

  render: ->
    `<span>{this.props.data}</span>`
