###* @jsx React.DOM ###

window.ResultsToolbar = React.createClass
  propTypes:
    results: React.PropTypes.object.isRequired

  hasMultipleResultPages: ->
    Object.keys(@props.results.pages).length > 1

  render: ->
    `<span>
      <div className="row-fluid search-result-toolbar">
        <div className="pull-left"></div>
      </div>
      {this.hasMultipleResultPages()
        ? <div className="pagination pagination-right">
            <ul>
              <li AAbindattr="" className="isShowingFirstPage:disabled" BB="">
                <a href="#" AAaction="" showfirstpageBB="">««</a>
              </li>
              <li AAbindattr="" className="isShowingFirstPage:disabled" BB="">
                <a href="#" AAaction="" showpreviouspageBB="">«</a>
              </li>
              <li><span>Page</span></li>
              <li><span className="paginator-counter">AAview App.CurrentPaginatorPageViewBB</span></li>
              <li><span>of AAnumPagesBB pages</span></li>
              <li AAbindattr="" className="isShowingLastPage:disabled" BB="">
                <a href="#" AAaction="" shownextpageBB="">»</a>
              </li>
              <li AAbindattr="" className="isShowingLastPage:disabled" BB="">
                <a href="#" AAaction="" showlastpageBB="">»»</a>
              </li>
            </ul>
          </div>
        : null}
    </span>`