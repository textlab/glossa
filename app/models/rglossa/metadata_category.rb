module Rglossa
  class MetadataCategory < ActiveRecord::Base
    attr_accessible :locale, :name, :corpus, :category_type, :value_type
    translates :name, fallbacks_for_empty_translations: true
    validates_presence_of :name
    validates_presence_of :category_type
    validates_presence_of :value_type

    belongs_to :corpus

    has_many :metadata_values, dependent: :destroy, order: :text_value
  end
end