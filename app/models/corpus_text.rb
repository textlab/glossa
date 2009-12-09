class CorpusText < ActiveRecord::Base
  belongs_to :corpus
  validates_presence_of :corpus_id
end
