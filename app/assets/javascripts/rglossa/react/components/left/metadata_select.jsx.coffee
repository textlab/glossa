###* @jsx React.DOM ###

window.MetadataSelect = React.createClass
  propTypes:
    category: React.PropTypes.object.isRequired
    collectMetadataValues: React.PropTypes.func.isRequired
    handleMetadataSelectionsChanged: React.PropTypes.func.isRequired

  getInitialState: ->
    isActive: false

  componentWillUnmount: ->
    $(@getDOMNode()).select2('destroy') if @state.isActive

  handleHeaderClick: ->
    node = @refs.hidden.getDOMNode()
    if @state.isActive
      @closeSelect(node)
    else
      @openSelect(node)

  openSelect: (node) ->
    @createSelect(node)
    $(node).select2('open')
    @setState(isActive: true)

  closeSelect: (node) ->
    @destroySelect(node)
    @setState(isActive: false)

  createSelect: (node) ->
    $(node).select2
      width: '100%'
      multiple: true
      placeholder: 'Click to select'
      ajax:
        url: "metadata_categories/#{@props.category.id}/metadata_values"
        dataType: 'json'

        data: (term, page) =>
          selectedMetadata = @props.collectMetadataValues()
          {query: term, page: page, metadata_value_ids: selectedMetadata}

        results: (data, page) =>
          {results: data.metadata_values}

    $(node).on 'change', =>
      @props.handleMetadataSelectionsChanged()


  destroySelect: (node) ->
    $(node).select2('destroy')
    $(node).val(null)

  getName: ->
    @props.category.id

  getValue: ->
    @refs.hidden.getDOMNode().value

  render: ->
      headerClasses = React.addons.classSet
        'category-header': true
        'active-category': @state.isActive

      `<span>
        <h5 className={headerClasses} onClick={this.handleHeaderClick}>
          {this.props.category.name}{this.state.isActive ? <span>  <i className="icon-remove-sign"></i></span> : null}
        </h5>
        <input ref="hidden" type="hidden" name={this.props.category.id} />
      </span>`
