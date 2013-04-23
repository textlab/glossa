module Rglossa
  module MetadataValues
    class Integer < MetadataValue
      def text
        integer_value.to_s
      end

      def text=(val)
        self.integer_value = val.to_i
      end

      # Converts a text value to a value of the type handled by this class
      def self.convert_text_value(value)
        value.to_i
      end
    end
  end
end