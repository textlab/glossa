# From http://davidwalsh.name/javascript-debounce-function

# Returns a function, that, as long as it continues to be invoked, will not
# be triggered. The function will be called after it stops being called for
# N milliseconds. If `immediate` is passed, trigger the function on the
# leading edge, instead of the trailing.
window.debounce = (func, wait, immediate) ->
  ->
    context = @
    args = arguments
    clearTimeout(timeout)
    timeout = setTimeout((->
      timeout = null
      func.apply(context, args) unless immediate), wait)
    if immediate && not timeout
      func.apply(context, args)
