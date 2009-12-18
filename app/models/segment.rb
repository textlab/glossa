class Segment < ActiveRecord::Base
  belongs_to :corpus_text
  validates_presence_of :corpus_text_id
end
