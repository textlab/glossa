if RAILS_ENV == 'development'
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

  title = TextMetadataValue.create!(:corpus_text => text, :metadata_category => MetadataCategory.find_by_name('title'))
  title.value = 'Peer Gynt'
  title.save!

  author = TextMetadataValue.create!(:corpus_text => text, :metadata_category => MetadataCategory.find_by_name('author'))
  author.value = 'Henrik Ibsen'
  author.save!

  year = IntegerMetadataValue.create!(:corpus_text => text, :metadata_category => MetadataCategory.find_by_name('publishing_year'))
  year.value = 1867
  year.save!

  user = User.create!(:username => 'testuser', :email => 'test@test.com',
                      :password => 'test', :password_confirmation => 'test')
  user_group = UserGroup.create!(:name => 'MyCorpusGroup')
  user_group.users << user
end
