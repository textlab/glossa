###* @jsx React.DOM ###

window.CwbMultiwordTerm = React.createClass
  propTypes:
    term: React.PropTypes.object.isRequired
    termIndex: React.PropTypes.number.isRequired
    queryHasSingleTerm: React.PropTypes.bool.isRequired
    isFirst: React.PropTypes.bool.isRequired
    isLast: React.PropTypes.bool.isRequired
    handleTermChanged: React.PropTypes.func.isRequired
    handleAddTerm: React.PropTypes.func.isRequired


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

  handleAddTerm: (e) ->
    e.preventDefault()
    @props.handleAddTerm()

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
                    <span className="add-on" title="Remove word" style={{cursor: 'pointer'}}><i className="icon-minus" /></span>
                    }

                    MENU
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

                <div className="tag-list" data-term-tags=""><div className="tags" /></div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>`
