if RAILS_ENV == 'development'
  corpus = Corpus.create!(:name => 'The Oslo Corpus of Tagged Norwegian Texts')
end
