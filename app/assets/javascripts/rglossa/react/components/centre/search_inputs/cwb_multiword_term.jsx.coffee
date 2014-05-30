###* @jsx React.DOM ###

window.CwbMultiwordTerm = React.createClass
  propTypes:
    term: React.PropTypes.object.isRequired
    termIndex: React.PropTypes.number.isRequired
    queryHasSingleTerm: React.PropTypes.bool.isRequired
    isFirst: React.PropTypes.bool.isRequired
    isLast: React.PropTypes.bool.isRequired
    handleTermChanged: React.PropTypes.func.isRequired


  handleTextChanged: (e) ->
    changedTerm = {}
    changedTerm[k] = @props.term[k] for k of @props.term  # clone the old term
    changedTerm.word = e.target.value                     # set its text value
    @props.handleTermChanged(changedTerm, @props.termIndex)


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
                  <input type="text" className="interval" value={term.min} /> min<br />
                  <input type="text" className="interval" value={term.max} /> max
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
                  <button className="btn btn-small" data-add-term-button="" title="Add search word">
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
                    <input type="checkbox" checked={term.isLemma} /> Lemma
                  </label>
                  &nbsp;&nbsp;
                  <label className="checkbox">
                    <input type="checkbox" title="Start of word" checked={term.isStart} /> Start
                  </label>
                  &nbsp;&nbsp;
                  <label className="checkbox">
                    <input type="checkbox" title="End of word" checked={term.isEnd} /> End
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
