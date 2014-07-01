#= require ./metadata_select

###* @jsx React.DOM ###

window.MetadataCategories = React.createClass
  propTypes:
    corpus: React.PropTypes.object.isRequired

  metadataCategory: (category) ->
    `<span key={category.id}>
      <h5 className="category-header">{category.name}</h5>
      <div>
        <MetadataSelect category={category} />
      </div>
    </span>`


  render: ->
    `<div id="left-sidebar" className="span3">
       <div>
         <form>
          {this.props.corpus.metadata_categories.map(this.metadataCategory)}
        </form>
      </div>
    </div>`
