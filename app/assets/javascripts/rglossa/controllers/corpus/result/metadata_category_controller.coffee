App.CorpusMetadataCategoryController = Em.ObjectController.extend

  collectMetadataValues: ->
    metadataValueIds = {}
    $('[data-metadata-selections] input[type="hidden"]').each (index, input) ->
      $input = $(input)
      val = $input.val()

      if val isnt ''
        name = $input.attr('name')
        metadataValueIds[name] = val.split(',')
    metadataValueIds
