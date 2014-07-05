###* @jsx React.DOM ###

window.MetadataSelect = React.createClass
  propTypes:
    category: React.PropTypes.object.isRequired
    collectMetadataValues: React.PropTypes.func.isRequired
    handleSelectedValuesChanged: React.PropTypes.func.isRequired

  getInitialState: ->
    isActive: false

  componentWillUnmount: ->
    $(@refs.hidden.getDOMNode()).select2('destroy') if @state.isActive

  componentDidUpdate: (prevProps, prevState) ->
    if prevState.isActive and !@state.isActive
      # We need setTimeout here because if the dropdown was closed by pressing
      # the escape key, select2 wants to focus the text field afterwards, and
      # it will throw an error if we have removed the field. By waiting until
      # the next run of the JavaScript run loop, we let select2 finish its thing
      # before removing it.
      setTimeout((=>
        $(@refs.hidden.getDOMNode()).select2('destroy')),
        0)


  handleHeaderClick: ->
    node = @refs.hidden.getDOMNode()
    if @state.isActive
      @closeSelect(node)
      @props.handleSelectedValuesChanged()
    else
      @openSelect(node)

  openSelect: (node) ->
    @createSelect(node)
    $(node).select2('open')
    @setState(isActive: true)

  closeSelect: (node = @refs.hidden.getDOMNode()) ->
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
      @props.handleSelectedValuesChanged()

    $(node).on 'select2-close', (e) =>
      unless e.target.value
        # If we close the dropdown (by clicking elsewhere or pressing
        # the escape key) and no values have been selected, set isActive
        # to false, which will cause the component to update and the text
        # field to be removed as well in componentDidUpdate (since we don't
        # want empty metadata text fields to stay around)
        @setState(isActive: false)


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
