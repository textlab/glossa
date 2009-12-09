class Corpus < ActiveRecord::Base
  has_many :language_configs
  has_many :corpus_texts
  has_and_belongs_to_many :metadata_categories

  validates_presence_of :name
end
