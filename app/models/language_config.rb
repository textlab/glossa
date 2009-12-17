class LanguageConfig < ActiveRecord::Base
  belongs_to :corpus
  validates_presence_of :corpus_id

  belongs_to :language_config_type
  validates_presence_of :language_config_type_id

  has_many :corpus_texts
end
