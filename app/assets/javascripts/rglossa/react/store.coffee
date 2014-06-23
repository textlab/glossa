class Store
  constructor: (models, @plurals, @storeChangedHandler, autoLoad = false) ->
    @models = {}
    @models[model] = {} for model in models
    @fetchData(models) if autoLoad

  getPlural: (singular) -> @plurals[singular] ? "#{singular}s"

  fetchData: (models) ->
    promises = for model in models
      do (model) =>
        $.getJSON(model)
          .done( (res) =>
            for data in res
              id = data.id
              @models[model][id] = data
            )
          .fail -> alert('Error fetching data from the server. Please reload the page.')
    $.when.apply(null, promises).done(=> @storeChangedHandler(@))


  find: (model, id) ->
    plural = @getPlural(model)
    data = @models[plural][id]
    return data if data?  # Store already contains the model

    # Store does not already contain the model, so fetch it
    url = "#{plural}/#{id}"
    $.getJSON(url)
      .done( (res) =>
        @setData(model, id, res[model])
        # Notify the client that the model has been loaded
        @storeChangedHandler(@))
      .fail -> alert('Error fetching data from the server. Please reload the page.')

    # Return null since the store did not contain the model. When the model has been
    # loaded, @storeChangedHandler will be called, and then the client can call `find`
    # again to retrieve the model.
    null


  setData: (model, id, data) ->
    plural = @getPlural(model)
    @models[plural][id] = data


window.Store = Store