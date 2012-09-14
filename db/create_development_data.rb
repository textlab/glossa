if Rails.env == 'development'
  corpus = Corpus.create!(:name => 'The Oslo Corpus of Tagged Norwegian Texts')

  corpus.metadata_categories.create!(:name => 'title', :fieldtype => 'text')
  corpus.metadata_categories.create!(:name => 'author', :fieldtype => 'text')
  corpus.metadata_categories.create!(:name => 'publishing_year', :fieldtype => 'integer')

  language_config_type = LanguageConfigType.create!(
          :name => "Norwegian bokmål, written, Constraint Grammar",
          :tagger => 'obt'
  )
  config = corpus.language_configs.create!(:language_config_type => language_config_type)

  text = config.corpus_texts.create!(:uri => 'peer_gynt.txt')

  title = MetadataValueText.create!(:corpus_text => text, :metadata_category => MetadataCategory.find_by_name('title'))
  title.value = 'Peer Gynt'
  title.save!

  author = MetadataValueText.create!(:corpus_text => text, :metadata_category => MetadataCategory.find_by_name('author'))
  author.value = 'Henrik Ibsen'
  author.save!

  year = MetadataValueInteger.create!(:corpus_text => text, :metadata_category => MetadataCategory.find_by_name('publishing_year'))
  year.value = 1867
  year.save!
end
