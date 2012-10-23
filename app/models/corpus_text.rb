class CorpusText < ActiveRecord::Base
  has_paper_trail

  belongs_to :language_config
  validates_presence_of :language_config_id

  has_many :segments
  has_many :metadata_values
  has_and_belongs_to_many :subcorpora
end
