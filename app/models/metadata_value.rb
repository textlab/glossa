class MetadataValue < ActiveRecord::Base
  belongs_to :metadata_category
  validates_presence_of :metadata_category_id
end
