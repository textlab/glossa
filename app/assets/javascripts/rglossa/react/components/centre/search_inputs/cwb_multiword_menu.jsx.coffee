###* @jsx React.DOM ###

window.CwbMultiwordMenu = React.createClass
  propTypes:
    tags: React.PropTypes.array
    handleAddPos: React.PropTypes.func.isRequired
    handleAddFeature: React.PropTypes.func.isRequired

  getDefaultProps: ->
    tags: []

  handleAddPos: (pos) ->
    @props.handleAddPos(pos)

  createPosMenu: (pos) ->
    if pos.features
      `<li className="dropdown-submenu">
        <a onClick={this.handleAddPos.bind(null, pos)}>{pos.name}</a>
        <ul className="dropdown-menu">
          {pos.features.map(this.createFeatureMenu.bind(this, pos))}
        </ul>
      </li>`
    else
      `<li>
        <a>{pos.name}</a>
      </li>`


  createFeatureMenu: (pos, feature) ->
    heading = if feature.name then `<li className="pos-feature-heading">{feature.name}</li>` else null
    options = feature.options.map ((option) ->
      `<li>
        <a onClick={this.props.handleAddFeature.bind(null, option, feature, pos)}>{option.name}</a>
      </li>`), this
    [heading, options]


  render: ->
      `<ul className="dropdown-menu">
        {this.props.tags.map(this.createPosMenu)}
      </ul>`