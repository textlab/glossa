module Rglossa
  module MetadataValues
    class Integer < MetadataValue
      def text
        integer_value.to_s
      end

      def text=(val)
        self.integer_value = val.to_i
      end
    end
  end
end