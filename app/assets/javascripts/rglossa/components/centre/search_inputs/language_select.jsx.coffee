#= require rglossa/models/corpus

###* @jsx React.DOM ###

window.LanguageSelect = React.createClass
  propTypes:
    corpus: React.PropTypes.object.isRequired
    selectedValue: React.PropTypes.string.isRequired
    index: React.PropTypes.number.isRequired
    handleChangeLanguage: React.PropTypes.func.isRequired

  onChange: (e) ->
    @props.handleChangeLanguage(this.props.index, e.target.value)

  render: ->
    languageList = corpusNs.getLanguageList(@props.corpus)

    `<select value={this.props.selectedValue} onChange={this.onChange}>
      {languageList.map(function(language) {
        return <option key={language.value} value={language.value}>{language.text}</option>
      })}
    </select>`
