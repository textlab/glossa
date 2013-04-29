module Rglossa
  class MetadataValue < ActiveRecord::Base
    belongs_to :metadata_category
    validates_presence_of :metadata_category_id

    def as_json(options={})
      opts = {only: :id, methods: :text}.merge(options)
      super(opts)
    end

    class << self

      def with_type_and_value(value_type, value)
        column = "#{value_type.demodulize.underscore}_value"
        value = value_type.constantize.convert_text_value(value)
        where(["#{column} = ?", value]).first
      end
    end
  end
end