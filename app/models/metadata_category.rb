class MetadataCategory < ActiveRecord::Base
  belongs_to :corpus
  has_many :metadata_values, dependent: :destroy

  validates_presence_of :name
  validates_presence_of :value_type
end
