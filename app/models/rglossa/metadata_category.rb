module Rglossa
  class MetadataCategory < ActiveRecord::Base
    self.table_name = "rglossa_metadata_categories"
    attr_accessible :locale, :short_name, :name, :corpus, :category_type, :value_type

    translates :name, fallbacks_for_empty_translations: true

    validates_presence_of :short_name
    validates_presence_of :category_type
    validates_presence_of :value_type

    belongs_to :corpus

    has_many :metadata_values,
             dependent: :destroy,
             order: :text_value,
             before_add: ->(category, value) { value.type = category.value_type }

    def vtype
      value_type.demodulize.underscore
    end

    def metadata_value_ids
      metadata_values.pluck(:id)
    end

    def get_metadata_value(value)
      metadata_values.with_type_and_value(value_type, value) ||
          metadata_values.create do |o|
            # For some reason, the before_add hook is not called here, so we cannot use the
            # text=() method of MetadataValue but need to figure out the correct column ourselves
            column = "#{value_type.demodulize.underscore}_value"
            o.update_attribute(column, value)
          end
    end
  end
end
