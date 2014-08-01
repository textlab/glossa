#= require ./metadata_select

###* @jsx React.DOM ###

window.MetadataCategories = React.createClass
  propTypes:
    corpus: React.PropTypes.object.isRequired
    handleMetadataSelectionsChanged: React.PropTypes.func.isRequired
    handleSidebarHidden: React.PropTypes.func.isRequired
    isMetadataSelectionEmpty: React.PropTypes.bool.isRequired

  componentWillReceiveProps: (nextProps) ->
    if nextProps.isMetadataSelectionEmpty and !@props.isMetadataSelectionEmpty
      # This indicates that the metadata selection was just cleared, possibly
      # through a click on the 'Reset form' button. Because the select2 lists are
      # stateful objects, we need to act on this trigger and destroy any open
      # select2 lists now.
      @closeAllSelects()

  componentWillLeave: (cb) ->
    $(@getDOMNode()).addClass('sidebar-leave-active')  # starts width transition

    # Calling the callback removes the sidebar div (we wait until the transition ends)
    # and calls componentDidLeave()
    setTimeout(cb, 100)


  componentDidLeave: ->
    # Now that the sidebar has been removed, handleSidebarHidden() will change the main
    # content width to be full-width (by changing its CSS classes to 'span12' and
    # 'no-sidebar')
    @props.handleSidebarHidden()


  componentWillEnter: (cb) ->
    # Begin by adding the sidebar-enter class, which sets the component's width to zero
    $(@getDOMNode()).addClass('sidebar-enter')

    # Call the callback on the next run of the JavaScript run loop, which in turn will
    # cause componentDidEnter() to be called.
    setTimeout(cb, 0)


  componentDidEnter: ->
    # Remove the sidebar-enter class that we added in componentWillEnter(). This will
    # cause the width of the component to be defined by its span3 class again, and the
    # width will transition from zero to the new width (as defined by the 'sidebar' CSS
    # class).
    $(@getDOMNode()).removeClass('sidebar-enter')

  handleSelectedValuesChanged: ->
    @props.handleMetadataSelectionsChanged(@collectMetadataValues())

  # Iterates through all the MetadataSelect components in the category list
  # and collects the ids of any selected metadata values. Will be used by owner components
  # to build the metadata selection that is to be included in the search. Will also be
  # called by the MetadataSelect components to restrict the set of values fetched from the
  # server; the server will only return values that are associated with those texts that are
  # also associated with the already selected values.
  collectMetadataValues: ->
    metadataValueIds = {}

    for name, select of @refs
      value = select.getValue()
      if value isnt ''
        name = select.getName()
        metadataValueIds[name] = value.split(',')

    metadataValueIds


  closeAllSelects: ->
    select.closeSelect() for name, select of @refs

  render: ->
    `<div id="left-sidebar" className="span3 sidebar">
       <div>
         <form>
          {this.props.corpus.metadata_categories.map(function(category) {
            return <MetadataSelect
                    key={category.id}
                    ref={category.id}
                    category={category}
                    collectMetadataValues={this.collectMetadataValues}
                    handleSelectedValuesChanged={this.handleSelectedValuesChanged} />
          }.bind(this))}
        </form>
      </div>
    </div>`
