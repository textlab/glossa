class Segment < ActiveRecord::Base
  belongs_to :corpus_text
  validates_presence_of :corpus_text_id

  validates_presence_of :contents

  has_and_belongs_to_many :aligned_segments, :class_name => 'Segment',
                          :join_table => 'aligned_segments',
                          :association_foreign_key => 'aligned_segment_id'
end
