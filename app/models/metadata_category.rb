class MetadataCategory < ActiveRecord::Base
  belongs_to :corpus
  has_many   :metadata_values, dependent: :destroy, order: :text_value

  validates_presence_of :name
  validates_presence_of :category_type
  validates_presence_of :value_type

  def name
    # Names that start with a colon should be localized; others should just be
    # returned as is
    name_attr = read_attribute(:name)
    name_attr.start_with?(':') ? I18n.t(name_attr[1..-1]) : name_attr
  end
end
