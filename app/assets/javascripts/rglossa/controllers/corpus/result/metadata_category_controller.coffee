App.CorpusMetadataCategoryController = Em.ObjectController.extend

  collectMetadataValues: ->
    metadataValueIds = {}
    $('input[type="hidden"][data-metadata-selection]').each (index, input) ->
      $input = $(input)
      val = $input.val()

      if val isnt ''
        name = $input.attr('name')
        metadataValueIds[name] = val.split(',')
    metadataValueIds
