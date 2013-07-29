App.MetadataSelectView = Em.View.extend

  tagName: 'input'
  attributeBindings: ['type', 'data-metadata-selection', 'name']
  type: 'hidden'
  'data-metadata-selection': 'data-metadata-selection'

  nameBinding: 'content.id'

  didInsertElement: ->
    @header = @$().parent().prev()

    @header.on 'click', =>
      if @isOpen
        @closeSelect()
      else
        @openSelect()


  willDestroyElement: ->
    @header.off 'click'


  openSelect: ->
    @createSelect()
    @$().select2('open')
    @isOpen = true
    @header.addClass('active-category')


  closeSelect: ->
    @destroySelect()
    @header.removeClass('active-category')
    @isOpen = false


  createSelect: ->
    @$().select2
      width: '100%'
      multiple: true
      placeholder: 'Click to select'
      ajax:
        url: "metadata_categories/#{@get('content.id')}/metadata_values"
        dataType: 'json'

        data: (term, page) =>
          selectedMetadata = @get('controller').collectMetadataValues()
          {query: term, page: page, metadata_value_ids: selectedMetadata}

        results: (data, page) =>
          {results: data.metadata_values}

    @$().on 'change', =>
      @get('controller').send('metadataSelectionsChanged')

  destroySelect: ->
    @$().select2('destroy')
    @$().val(null)
