class Corpus
  getLanguages: (corpus) -> corpus.langs

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


window.corpus = new Corpus