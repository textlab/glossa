###* @jsx React.DOM ###

window.CwbMultiwordTerm = React.createClass
  propTypes:
    term: React.PropTypes.object.isRequired
    queryHasSingleTerm: React.PropTypes.bool.isRequired

  render: ->
    {term, queryHasSingleTerm} = @props

    `<div style={{display: 'table-cell'}}>
      <div style={{display: 'table'}}>
        <div className="multiword-term">
          <div className="control-group">
            <div style={{display: 'table-row'}}>

              {term.isFirst ? '' :
              <div className="interval">
                <h6>Interval</h6>
                <input type="text" className="interval" value={term.min} min /><br />
                <input type="text" className="interval" value={term.max} max />
              </div>
              }

              <div className="input-prepend input-append word">
                <div className="dropdown">
                  <span data-toggle="dropdown" className="add-on dropdown-toggle" style={{cursor: 'pointer'}}><i className="icon-cog" /></span>
                  <input type="text" className="searchfield multiword-field removable" value={term.word} />

                  {queryHasSingleTerm ? '' :
                  <span className="add-on" title="Remove word" style={{cursor: 'pointer'}}><i className="icon-minus" /></span>
                  }

                  MENU
                </div>
              </div>

              {term.isLast ?
              <div className="add-search-word">
                <button className="btn btn-small" data-add-term-button="" title="Add search word">
                  <i className="icon-plus" />
                </button>
              </div>
              : ''}

            </div>
            <div style={{display: 'table-row'}}>

              {term.isFirst ? '' :
              <div className="interval-filler" style={{display: 'table-cell'}}>
              </div>
              }

              <div className="word-checkboxes">
                <label className="checkbox">
                  <input type="checkbox" checked={term.isLemma} /> Lemma
                </label>
                <label className="checkbox">
                  <input type="checkbox" title="Start of word" checked={term.isStart} /> Start
                </label>
                <label className="checkbox">
                  <input type="checkbox" title="End of word" checked={term.isEnd} /> End
                </label>
                <div style={{display: 'table-cell'}}>
                </div>
              </div>
            </div>
            <div style={{display: 'table-row'}}>

              {term.isFirst ? '' :
              <div className="interval-filler" style={{display: 'table-cell'}}>
              </div>
              }

              <div className="tag-list" data-term-tags=""><div className="tags" /></div>
            </div>
          </div>
        </div>
      </div>
    </div>`
