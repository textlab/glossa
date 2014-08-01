#= require rglossa/models/corpus

###* @jsx React.DOM ###

window.LanguageSelect = React.createClass
  propTypes:
    corpus: React.PropTypes.object.isRequired
    selectedValue: React.PropTypes.string.isRequired


  render: ->
    languageList = corpusNs.getLanguageList(@props.corpus)

    `<select value={this.props.selectedValue}>
      {languageList.map(function(language) {
        return <option key={language.value} value={language.value}>{language.text}</option>
      })}
    </select>`
