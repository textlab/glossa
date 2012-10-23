class CorpusText < ActiveRecord::Base
  belongs_to :language_config

  has_many :segments
  has_many :metadata_values
  has_and_belongs_to_many :subcorpora
end
