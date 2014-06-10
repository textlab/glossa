#= require ./cwb_multiword_menu

###* @jsx React.DOM ###

window.CwbMultiwordTerm = React.createClass
  propTypes:
    term: React.PropTypes.object.isRequired
    termIndex: React.PropTypes.number.isRequired
    queryHasSingleTerm: React.PropTypes.bool.isRequired
    isFirst: React.PropTypes.bool.isRequired
    isLast: React.PropTypes.bool.isRequired
    tags: React.PropTypes.array.isRequired
    handleTermChanged: React.PropTypes.func.isRequired
    handleAddTerm: React.PropTypes.func.isRequired
    handleRemoveTerm: React.PropTypes.func.isRequired

  componentDidMount: ->
    tagsInput = $(@refs.taglist.getDOMNode()).tags(
        promptText: ' '
        afterDeletingTag: @afterDeletingTag)

    term = @props.term
    tagsInput.addTag(term.pos) if term.pos
    tagsInput.addTag(feature.value) for feature in term.features


  componentWillUnmount: ->
    $(@refs.taglist.getDOMNode()).tags('destroy')


  componentWillReceiveProps: (nextProps) ->
    # When we receive new props, we need to add any newly selected POS or
    # features. We don't need to worry about removing any, because they
    # can only be removed either by a) clicking on a tag in the list, in
    # which case bootstrap-tags will remove it itself, or b) editing the
    # search expression in the regex view, in which case the multiword view
    # will be mounted anew when we switch to it and the tags will be set up
    # by componentDidMount.

    tagsInput = $(@refs.taglist.getDOMNode()).tags()

    if nextProps.term.pos isnt @props.term.pos
      if @props.term.pos
        tagsInput.renameTag(@props.term.pos, nextProps.term.pos)
      else
        tagsInput.addTag(nextProps.term.pos)

    currentFeatures = @props.term.features
    newFeatures = nextProps.term.features.filter (f) ->
      not currentFeatures.some (cf) -> cf.attr is f.attr and cf.value is f.value

    tagsInput.addTag(feature.value) for feature in newFeatures


  changeTerm: (attribute, value) ->
    changedTerm = {}
    changedTerm[k] = @props.term[k] for k of @props.term  # clone the old term
    changedTerm[attribute] = value
    @props.handleTermChanged(changedTerm, @props.termIndex)

  handleTextChanged: (e) -> @changeTerm('word', e.target.value)

  handleMinChanged: (e) -> @changeTerm('min', e.target.value)

  handleMaxChanged: (e) -> @changeTerm('max', e.target.value)

  handleIsLemmaChanged: (e) -> @changeTerm('isLemma', e.target.checked)

  handleIsStartChanged: (e) -> @changeTerm('isStart', e.target.checked)

  handleIsEndChanged: (e) -> @changeTerm('isEnd', e.target.checked)

  handleAddPos: (pos) -> @changeTerm('pos', pos.value)

  handleAddFeature: (option, feature) ->
    features = @props.term.features.slice(0)
    features.push
      attr: feature.attr
      value: option.value
    @changeTerm('features', features)

  handleAddTerm: (e) ->
    e.preventDefault()
    @props.handleAddTerm()

  handleRemoveTerm: (e) ->
    @props.handleRemoveTerm(@props.termIndex)

  # Called by the bootstrap-tags plugin after it has removed a tag
  afterDeletingTag: (tag) ->
    term = @props.term
    if tag is term.pos then @removePos() else @removeFeature(tag)

  removePos: -> @changeTerm('pos', null)

  removeFeature: (tag) ->
    features = @props.term.features.filter (f) -> f.value isnt tag
    @changeTerm('features', features)


  render: ->
    {term, queryHasSingleTerm, isFirst, isLast} = @props

    `<div style={{display: 'table-cell'}}>
      <div style={{display: 'table-cell'}}>
        <div style={{display: 'table'}}>
          <div className="multiword-term">
            <div className="control-group">
              <div style={{display: 'table-row'}}>

                {isFirst ? null :
                <div className="interval">
                  <h6>Interval</h6>
                  <input type="text" className="interval" value={term.min} onChange={this.handleMinChanged} /> min<br />
                  <input type="text" className="interval" value={term.max} onChange={this.handleMaxChanged} /> max
                </div>
                }

                <div className="input-prepend input-append word">
                  <div className="dropdown">
                    <span data-toggle="dropdown" className="add-on dropdown-toggle" style={{cursor: 'pointer'}}><i className="icon-cog" /></span>
                    <input type="text" className="searchfield multiword-field removable"
                      defaultValue={term.word} onChange={this.handleTextChanged} />

                    {queryHasSingleTerm ? null :
                    <span className="add-on" title="Remove word" style={{cursor: 'pointer'}} onClick={this.handleRemoveTerm} ><i className="icon-minus" /></span>
                    }

                    <CwbMultiwordMenu tags={this.props.tags.options} handleAddPos={this.handleAddPos} handleAddFeature={this.handleAddFeature} />
                  </div>
                </div>

                {isLast ?
                <div className="add-search-word">
                  <button className="btn btn-small" data-add-term-button="" title="Add search word" onClick={this.handleAddTerm} >
                    <i className="icon-plus" />
                  </button>
                </div>
                : null}

              </div>
              <div style={{display: 'table-row'}}>

                {isFirst ? null :
                <div className="interval-filler" style={{display: 'table-cell'}}>
                </div>
                }

                <div className="word-checkboxes">
                  <label className="checkbox">
                    <input type="checkbox" checked={term.isLemma} onChange={this.handleIsLemmaChanged} /> Lemma
                  </label>
                  &nbsp;&nbsp;
                  <label className="checkbox">
                    <input type="checkbox" title="Start of word" checked={term.isStart} onChange={this.handleIsStartChanged} /> Start
                  </label>
                  &nbsp;&nbsp;
                  <label className="checkbox">
                    <input type="checkbox" title="End of word" checked={term.isEnd} onChange={this.handleIsEndChanged} /> End
                  </label>
                  <div style={{display: 'table-cell'}}>
                  </div>
                </div>
              </div>
              <div style={{display: 'table-row'}}>

                {isFirst ? null :
                <div className="interval-filler" style={{display: 'table-cell'}}>
                </div>
                }

                <div className="tag-list" ref="taglist"><div className="tags" /></div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>`
