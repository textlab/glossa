#= require ./metadata_select

###* @jsx React.DOM ###

window.MetadataCategories = React.createClass
  propTypes:
    corpus: React.PropTypes.object.isRequired
    handleMetadataSelectionsChanged: React.PropTypes.func.isRequired


  # Iterates through all the MetadataSelect components in the category list
  # and collects the ids of any selected metadata values. Will be called by the
  # MetadataSelect components to restrict the set of values fetched from the server;
  # the server will only return values that are associated with those texts that are
  # also associated with the already selected values.
  collectMetadataValues: ->
    metadataValueIds = {}

    for name, select of @refs
      value = select.getValue()
      if value isnt ''
        name = select.getName()
        metadataValueIds[name] = value.split(',')

    metadataValueIds


  metadataCategory: (category) ->

  render: ->
    `<div id="left-sidebar" className="span3">
       <div>
         <form>
          {this.props.corpus.metadata_categories.map(function(category) {
            return <MetadataSelect
                    key={category.id}
                    ref={category.id}
                    category={category}
                    collectMetadataValues={this.collectMetadataValues}
                    handleMetadataSelectionsChanged={this.props.handleMetadataSelectionsChanged} />
          }.bind(this))}
        </form>
      </div>
    </div>`