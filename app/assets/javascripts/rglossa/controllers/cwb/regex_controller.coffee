App.CwbRegexController = Em.Controller.extend

  needs: ['cwbSearchInputs']

  # "query" is defined on each of the different controllers for the simple,
  # multiword and regex CWB search and bound to the CwbSearchInputsController, which
  # will create the search records.
  queryBinding: 'controllers.cwbSearchInputs.query'
