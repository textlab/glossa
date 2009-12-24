class MetadataValue < ActiveRecord::Base
  belongs_to :metadata_category
  validates_presence_of :metadata_category_id

  belongs_to :corpus_text
  validates_presence_of :corpus_text_id
end
