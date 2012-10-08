# encoding: utf-8
#
# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ :name => 'Chicago' }, { :name => 'Copenhagen' }])
#   Mayor.create(:name => 'Daley', :city => cities.first)

corpus = Corpus.create!(:name => 'The Oslo Corpus of Tagged Norwegian Texts')

corpus.metadata_categories.create!(:name => 'title', :fieldtype => 'text')
corpus.metadata_categories.create!(:name => 'author', :fieldtype => 'text')
corpus.metadata_categories.create!(:name => 'publishing_year', :fieldtype => 'integer')

title = MetadataValueText.create!(:metadata_category => MetadataCategory.find_by_name('title'))
title.value = 'Peer Gynt'
title.save!

author = MetadataValueText.create!(:metadata_category => MetadataCategory.find_by_name('author'))
author.value = 'Henrik Ibsen'
author.save!

year = MetadataValueInteger.create!(:metadata_category => MetadataCategory.find_by_name('publishing_year'))
year.value = 1867
year.save!
