class MetadataCategory < ActiveRecord::Base
  include LocalizationSupport

  belongs_to :corpus
  has_many   :metadata_values, dependent: :destroy, order: :text_value

  validates_presence_of :name
  validates_presence_of :category_type
  validates_presence_of :value_type

  def name
    localized_attribute(:name)
  end
end
