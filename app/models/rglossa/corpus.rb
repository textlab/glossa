require 'globalize3'

module Rglossa
  class Corpus < ActiveRecord::Base
    attr_accessible :locale, :name, :short_name

    translates :name, fallbacks_for_empty_translations: true

    validates_presence_of :name

    has_many :metadata_categories,
             dependent: :destroy,
             order: :short_name,
             before_add: :set_metadata_value_type

    def metadata_category_ids
      metadata_categories.pluck(:id)
    end

    # This lets us specify a value_type of 'text', 'integer' etc. when we add a metadata category
    # and have it be automatically converted to 'Rglossa::MetadataValues::Text' etc. before the
    # category is saved.
    def set_metadata_value_type(category)
      unless category.value_type.start_with?("Rglossa")
        category.value_type = "Rglossa::MetadataValues::#{category.value_type.classify}"
      end
    end
  end
end