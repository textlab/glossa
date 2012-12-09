module Rglossa
  module MetadataValues
    class Text < MetadataValue
      def text
        text_value
      end

      def text=(val)
        self.text_value = val.to_s
      end
    end
  end
end