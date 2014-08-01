class Corpus
  getLanguages: (corpus) -> corpus.langs

  getLanguageList: (corpus) ->
    languages = @getLanguages(corpus)
    for language in languages
      value: language.lang
      text: i18n.translate(language.lang).onDomain('languages').fetch()

  getLanguage: (corpus, languageCode) ->
    languages = @getLanguages(corpus)

    if languageCode is 'single'  # monolingual corpus
      languages[0]
    else
      (language in languages where language.lang is languageCode)?[0]


  getLabels: (corpus, languageCode = 'single') ->
    language = @getLanguage(corpus, languageCode)
    language.displayAttrs or corpus.displayAttrs or []

  getPOSAttribute: (corpus, languageCode = 'single') ->
    language = @getLanguage(corpus, languageCode)
    language.tags?.attr or 'pos'

  getTags: (corpus, languageCode = 'single') ->
    language = @getLanguage(corpus, languageCode)
    language.tags

  isMultilingual: (corpus) ->
    @getLanguages(corpus).length > 1


window.corpusNs = new Corpus