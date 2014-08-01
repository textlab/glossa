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
    @findBy(model, 'id', id)

  # Looks up the model in the store by the given attribute, assuming that this attribute
  # will be the one that is used as the key in the store. If the model is not already
  # loaded, we send a request to the server to fetch it. If the attribute is 'id', we
  # use the normal RESTful plural-model-name/id approach which will cause the 'show' method
  # to be called in Rails; otherwise we use plural-model-name/find_by?attribute=value, which
  # will have to be supported by the Rails controller for the resouce.
  findBy: (model, attribute, value) ->
    plural = @getPlural(model)
    data = @models[plural][value]
    return data if data?  # Store already contains the model

    # Store does not already contain the model, so fetch it
    url = if attribute is 'id'
            "#{plural}/#{value}"
          else
            "#{plural}/find_by?#{attribute}=#{value}"

    $.getJSON(url)
      .done( (res) =>
        @setData(model, value, res[model])
      )
      .fail -> alert('Error fetching data from the server. Please reload the page.')

    # Return null since the store did not contain the model. When the model has been
    # loaded, @storeChangedHandler will be called (via @setData), and then the client
    # can call `find` again to retrieve the model.
    null


  setData: (model, id, data) ->
    plural = @getPlural(model)
    @models[plural][id] = data
    # Notify the client that the model has been loaded
    @storeChangedHandler(@)


window.Store = Store