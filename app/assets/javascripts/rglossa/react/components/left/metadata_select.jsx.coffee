###* @jsx React.DOM ###

window.MetadataSelect = React.createClass
  propTypes:
    category: React.PropTypes.object.isRequired
    collectMetadataValues: React.PropTypes.func.isRequired
    handleMetadataSelectionsChanged: React.PropTypes.func.isRequired

  componentDidMount: ->
    node = @getDOMNode()
    @header = $(node).parent().prev()

    @header.on 'click', =>
      if @isOpen
        @closeSelect(node)
      else
        @openSelect(node)


  componentWillUnmount: ->
    @header.off 'click'

  openSelect: (node) ->
    @createSelect(node)
    $(node).select2('open')

    @isOpen = true
    @header.addClass('active-category')

  closeSelect: (node) ->
    @destroySelect(node)
    @header.removeClass('active-category')
    @isOpen = false

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
    `<input ref="hidden" type="hidden" name={this.props.category.id} />`
