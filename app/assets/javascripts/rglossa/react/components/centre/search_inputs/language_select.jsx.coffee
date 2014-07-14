#= require rglossa/react/models/corpus

###* @jsx React.DOM ###

window.LanguageSelect = React.createClass
  propTypes:
    corpus: React.PropTypes.object.isRequired


  render: ->
    languageList = corpusNs.getLanguageList(@props.corpus)

    `<select>
      {languageList.map(function(language) {
        return <option key={language.value} value={language.value}>{language.text}</option>
      })}
    </select>`
