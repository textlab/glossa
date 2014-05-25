createStates = (statechart, parent, configs) ->
  states = {}
  for name, config of configs
    actions = config.actions or {}
    substates = config.substates or {}
    initialSubstate = config.initialSubstate
    states[name] = new State(statechart, parent, name, actions,
      substates, initialSubstate)
  states


class Statechart
  constructor: (@name, root, @currentStateChangedHandler) ->
    actions = root.actions or {}
    substates = root.substates or {}
    initialSubstate = root.initialSubstate
    @root = new State(@, null, 'root', actions, substates, initialSubstate)
    @root.transitionTo(initialSubstate)

  setCurrentState: (@currentState) ->
    # Call the handler provided by our creator even if the new state might be the same
    # as the old one, since we might have set different args data along the way (e.g. when
    # we move from one page of paginated data to another, displayed in the same
    # state but with a different page number provided in the args structure).
    @currentStateChangedHandler(@) if @currentStateChangedHandler


  getCurrentPath: -> @currentState.getPath()

  # Searches for a state argument (i.e. data stored in the args property on a state)
  # that matches the given name, beginning at the current state and working upwards
  # towards the root state.
  getArgumentValue: (argname) ->
    state = @currentState
    while state
      value = state.args?[argname]
      return value if value?
      state = state.parent
    return null

  # Checks whether the current state path contains the given subpath, which
  # should be a string of one or more state names separated by a slash
  # (e.g. "posts" or "posts/editing"). Components can use this to customize
  # their behaviour or rendering depending on the current state.
  pathContains: (subpath) ->
    new RegExp(subpath).test(@getCurrentPath()) # use RegExp to avoid escaping the slash

  # Handles an action sent by a React component, the server etc.
  # The action will be handled by the first state that
  # defines a method named after the action, beginning at the current
  # state and working upwards towards the root state. This allows the
  # behaviour of the system to depend on the current state.
  handleAction: (action, data...) ->
    state = @currentState
    while state
      handler = state.actions?[action]
      if handler
        handler.apply(state, data)
        return
      else
        state = state.parent
    console?.warn?("No state handled the action '#{action}'")


class State
  constructor: (@statechart, @parent, @name, @actions, substates, @initialSubstate) ->
    @substates = createStates(statechart, @, substates)

    unless initialSubstate or @isLeaf()
      throw new Error("Missing initialSubstate for #{@getPath()}")

  # Transitions to a state located at the given path, with path being a UNIX-style
  # absolute or relative path. In the case of a relative path, it will be relative
  # to the `this` state, which is normally a state handling an action and
  # calling `transitionTo` in its action handler. This means that the state
  # we transition to only depends on the one handling the action, not the
  # current application state, and this is typically what we want: the same action
  # will always put us into the same state no matter which substate we were
  # in prior to the action being sent.
  #
  # The `args` argument will be set on the last state mentioned in the path (which
  # will be the final target state only if it is a leaf state) and can be used to
  # provide component code with additional data. For instance, when showing a paginated
  # set of search results, we typically don't want to have a separate state for each
  # page, but rather a single result state with an `args` property set to something
  # like {currentPageNo: 1}.
  transitionTo: (path, args) ->
    [start, segments...] = path.split('/')

    if start
      # relative path
      startState = @
      segments.unshift(start)
    else
      # absolute path
      startState = @statechart.root

    targetState = startState.traversePath(segments)

    # Set args on the last state explicitly mentioned in the path, even though we may actually
    # traverse further by following initialSubstate properties until we reach a leaf state.
    if args?
      targetState.args = args
      argsMsg = " with the following args set on #{targetState.getPath()}:" if window.console

    # Unless targetState is already a leaf state, traverse further until we reach one
    while targetState.initialSubstate
      targetState = targetState.substates[targetState.initialSubstate]

    if targetState.isLeaf()
      @statechart.setCurrentState(targetState)
      if window.console
        msg = "#{@statechart.name}: Transitioned to #{targetState.getPath()}"
        msg += argsMsg if argsMsg
        console.log(msg)
        console.log(args) if args?
    else
      throw new Error("Trying to transition to non-leaf state '#{targetState.getPath()}'!")

  traversePath: (segments) ->
    firstSegment = segments.shift()
    if firstSegment
      nextState = switch firstSegment
        when '.' then @
        when '..' then @parent or throw new Error("Trying to traverse beyond root state!")
        else @substates[firstSegment] or throw new Error("Trying to traverse to non-existent substate '#{firstSegment}'!")
      nextState.traversePath(segments)
    else @  # there were no more path segments, so this state is the traversal target

  getPath: -> if @parent then "#{@parent.getPath()}/#{@name}" else '' # don't include the name of 'root'

  isLeaf: ->
    return false for k of @substates  # returns false if @substates is non-empty
    true


window.Statechart = Statechart
window.State = State
