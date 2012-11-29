# encoding: utf-8
#
# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ :name => 'Chicago' }, { :name => 'Copenhagen' }])
#   Mayor.create(:name => 'Daley', :city => cities.first)

corpus = Corpus.create!(name: 'The Corpus for Bokmål Lexicography')

title = MetadataCategory.create!(
  corpus: corpus,
  name: 'Title',
  category_type: 'list',
  value_type: 'text'
)
MetadataValueText.create([
  { metadata_category: title, text: 'Peer Gynt' },
  { metadata_category: title, text: 'Vildanden' },
  { metadata_category: title, text: 'Brand' }
  ])

author = MetadataCategory.create!(
  corpus: corpus,
  name: 'Author',
  category_type: 'list',
  value_type: 'text'
)
MetadataValueText.create([
  { metadata_category: author, text: 'Henrik Ibsen' },
  { metadata_category: author, text: 'Ingvar Ambjørnsen' },
  { metadata_category: author, text: 'Erlend Loe' }
  ])

publ_year = MetadataCategory.create!(
  corpus: corpus,
  name: 'Published',
  category_type: 'list',
  value_type: 'integer'
)

sex = MetadataCategory.create!(
  corpus: corpus,
  name: 'Sex',
  category_type: 'shortlist',
  value_type: 'text'
)

MetadataValueInteger.create!(metadata_category: publ_year, text: 1867)
MetadataValueText.create!(metadata_category: sex, text: 'male')
