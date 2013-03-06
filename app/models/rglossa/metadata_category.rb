module Rglossa
  class MetadataCategory < ActiveRecord::Base
    attr_accessible :locale, :short_name, :name, :corpus, :category_type, :value_type

    translates :name, fallbacks_for_empty_translations: true

    validates_presence_of :short_name
    validates_presence_of :category_type
    validates_presence_of :value_type

    belongs_to :corpus

    has_many :metadata_values,
             dependent: :destroy,
             order: :text_value,
             before_add: ->(value) { value.type = value_type }

    def metadata_value_ids
      metadata_values.pluck(:id)
    end
  end
end