# encoding: utf-8
#
# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ :name => 'Chicago' }, { :name => 'Copenhagen' }])
#   Mayor.create(:name => 'Daley', :city => cities.first)

corpus = Corpus.create!(:name => 'Leksikografisk bokmålskorpus')

title_cat = MetadataCategoryList.create!(corpus: corpus, name: ':title', value_type: 'text')
author_cat = MetadataCategoryList.create!(corpus: corpus, name: ':author', value_type: 'text')
publ_year_cat = MetadataCategoryList.create!(corpus: corpus, name: ':publishing_year', value_type: 'integer')
sex_cat = MetadataCategoryShortList.create!(corpus: corpus, name: ':author_sex', value_type: 'text')

MetadataValueText.create!(metadata_category: title_cat, text: 'Peer Gynt')
MetadataValueText.create!(metadata_category: author_cat, text: 'Henrik Ibsen')
MetadataValueInteger.create!(metadata_category: publ_year_cat, text: 1867)
MetadataValueText.create!(metadata_category: sex_cat, text: 'male')
