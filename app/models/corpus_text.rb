class CorpusText < ActiveRecord::Base
  has_and_belongs_to_many :metadata_values
end
