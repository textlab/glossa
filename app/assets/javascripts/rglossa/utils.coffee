window.rglossaUtils =
  capitalize: (str) ->
    return '' unless str.length
    (str.split('_').map (part) -> part[0].toUpperCase() + part.slice(1)).join('')


  # From http://davidwalsh.name/javascript-debounce-function

  # Returns a function, that, as long as it continues to be invoked, will not
  # be triggered. The function will be called after it stops being called for
  # N milliseconds. If `immediate` is passed, trigger the function on the
  # leading edge, instead of the trailing.
  debounce: (func, wait, immediate) ->
    timeout = null
    ->
      context = @
      args = arguments
      clearTimeout(timeout)
      timeout = setTimeout((->
        timeout = null
        func.apply(context, args) unless immediate), wait)
      if immediate && not timeout
        func.apply(context, args)


  # Merges the key/value pairs from obj1 and obj2 into one object, with pairs
  # from obj2 overriding any pairs from obj1 with identical keys.
  merge: (obj1, obj2) ->
    res = {}
    res[key] = value for key, value of obj1
    res[key] = value for key, value of obj2
    res


  withoutPrefix: (str, prefix) ->
    if str.substr(0, prefix.length) == prefix
      str.substr(prefix.length)
    else
      str


  withoutSuffix: (str, suffix) ->
    if str.substr(-suffix.length) == suffix
      str.substr(0, str.length - suffix.length)
    else
      str
