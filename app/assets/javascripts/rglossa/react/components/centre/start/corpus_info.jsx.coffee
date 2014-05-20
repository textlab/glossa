###* @jsx React.DOM ###

window.CorpusInfo = React.createClass
  propTypes:
    corpusName: React.PropTypes.string.isRequired
    corpusLogoUrl: React.PropTypes.string

  render: ->
      `<div className="row-fluid corpus-info">
        <div className="span12">
          <div className="well">
            <h2>
              {this.props.corpusName}
              {this.props.corpusLogoUrl ? <img className="corpus-logo" src={this.props.corpusLogoUrl} /> : ''}
            </h2>
          </div>
        </div>
      </div>`
