###* @jsx React.DOM ###

window.CorpusInfo = React.createClass
  propTypes:
    corpusName: React.PropTypes.string.isRequired
    corpusLogoUrl: React.PropTypes.string

  render: ->
    `<div className="row-fluid corpus-info">
      <div className="span9">
        <div className="well">
          <h2>
            <span dangerouslySetInnerHTML={{__html: this.props.corpusName}} />
          </h2>
        </div>
      </div>
      <div className="span3" style={{position: 'relative'}}>
      {this.props.corpusLogoUrl ? <img className="corpus-logo" src={this.props.corpusLogoUrl} /> : ''}
      </div>
    </div>`
