###* @jsx React.DOM ###

window.MetadataSelect = React.createClass
  propTypes:
    category: React.PropTypes.object.isRequired

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

        # data: (term, page) =>
        #   selectedMetadata = @get('controller').collectMetadataValues()
        #   {query: term, page: page, metadata_value_ids: selectedMetadata}

        results: (data, page) =>
          {results: data.metadata_values}

    # $(node).on 'change', =>
    #   @get('controller').send('metadataSelectionsChanged')


  destroySelect: (node) ->
    $(node).select2('destroy')
    $(node).val(null)

  render: ->
    `<input type="hidden" name={this.props.category.id} data-metadata-selection="data-metadata-selection" />`
