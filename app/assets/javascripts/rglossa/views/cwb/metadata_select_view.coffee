App.MetadataSelectView = Em.View.extend

  tagName: 'input type="hidden"'
  attributeBindings: ['name']

  nameBinding: 'content.id'

  didInsertElement: ->
    @header = @$().parent().prev()

    @header.on 'click', =>
      if @isOpen
        @destroySelect()
        @header.removeClass('active-category')
        @isOpen = false
      else
        @createSelect()
        @$().select2('open')
        @isOpen = true
        @header.addClass('active-category')


  willDestroyElement: ->
    @header.off 'click'


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
