module Rglossa
  module MetadataValues
    class Text < MetadataValue
      def text
        text_value || ''
      end

      def text=(val)
        self.text_value = val.to_s
      end

      # Converts a text value to a value of the type handled by this class
      def self.convert_text_value(value)
        value
      end

      def self.search(query, scope = scoped)
        scope.where('text_value LIKE ?', "%#{query}%")
      end
    end
  end
end