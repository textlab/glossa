#= require ./main_area_top
#= require ./main_area_bottom

###* @jsx React.DOM ###

window.MainArea = React.createClass
  propTypes:
    statechart: React.PropTypes.object.isRequired
    corpus: React.PropTypes.object.isRequired

  showCorpusHome: ->
    alert 'showCorpusHome'

  render: ->
    `<span>
      <div className="container-fluid">

        <MainAreaTop
          statechart={this.props.statechart} />

        <MainAreaBottom
          statechart={this.props.statechart}
          corpus={this.props.corpus} />

      </div>
    </span>`
