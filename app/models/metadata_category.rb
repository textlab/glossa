class MetadataCategory < ActiveRecord::Base
  belongs_to :corpus
  has_many   :values, class_name: 'MetadataValue', dependent: :destroy, order: :name

  validates_presence_of :name
  validates_presence_of :category_type
  validates_presence_of :value_type

  def localized_name
    # Names that start with a colon should be localized; others should just be
    # returned as is
    name.start_with?(':') ? I18n.t(name[1..-1]) : name
  end
end
