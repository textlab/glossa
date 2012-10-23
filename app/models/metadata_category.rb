class MetadataCategory < ActiveRecord::Base
  include LocalizationSupport

  belongs_to :corpus
  has_many   :metadata_values, dependent: :destroy, order: :text_value

  translates :name, versioning: true, fallbacks_for_empty_translations: true
  validates_presence_of :name
  validates_presence_of :category_type
  validates_presence_of :value_type

  def name
    localized_attribute(:name)
  end
end
