class MetadataCategory < ActiveRecord::Base
  has_and_belongs_to_many :corpora

  validates_presence_of :name
  validates_presence_of :fieldtype
end
