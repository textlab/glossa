class LanguageConfig < ActiveRecord::Base
  belongs_to :corpus
  validates_presence_of :corpus_id

  validates_presence_of :name
end
