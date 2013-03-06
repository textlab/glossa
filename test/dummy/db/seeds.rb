# encoding: utf-8
#
# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ :name => 'Chicago' }, { :name => 'Copenhagen' }])
#   Mayor.create(:name => 'Daley', :city => cities.first)

module Rglossa
  corpus = Corpus.create!(
      short_name: 'RUN_EN',
      name: 'The Corpus for Bokmål Lexicography')

  title = MetadataCategory.create!(
      corpus: corpus,
      short_name: 'title',
      category_type: 'list',
      value_type: 'text'
  )
  MetadataValues::Text.create(
      [
          { metadata_category: title, text: 'Peer Gynt' },
          { metadata_category: title, text: 'Vildanden' },
          { metadata_category: title, text: 'Brand' }
      ]
  )

  author = MetadataCategory.create!(
      corpus: corpus,
      short_name: 'author',
      category_type: 'list',
      value_type: 'text'
  )
  MetadataValues::Text.create(
      [
          { metadata_category: author, text: 'Henrik Ibsen' },
          { metadata_category: author, text: 'Ingvar Ambjørnsen' },
          { metadata_category: author, text: 'Erlend Loe' }
      ]
  )

  publ_year = MetadataCategory.create!(
      corpus: corpus,
      short_name: 'published',
      category_type: 'list',
      value_type: 'integer'
  )

  sex = MetadataCategory.create!(
      corpus: corpus,
      short_name: 'sex',
      category_type: 'shortlist',
      value_type: 'text'
  )

  MetadataValues::Integer.create!(metadata_category: publ_year, text: 1867)
  MetadataValues::Text.create!(metadata_category: sex, text: 'male')
end