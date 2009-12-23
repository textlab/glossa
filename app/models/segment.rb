class Segment < ActiveRecord::Base
  belongs_to :corpus_text
  validates_presence_of :corpus_text_id

  validates_presence_of :contents

  # This is only relevant for corpora that contains aligned text segments, such as parallel corpora
  # or spoken language corpora with aligned phonetic and orthographic transcriptions.
  has_and_belongs_to_many :aligned_segments, :class_name => 'Segment',
                          :join_table => 'aligned_segments',
                          :association_foreign_key => 'aligned_segment_id'
end
