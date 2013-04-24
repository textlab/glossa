module Rglossa
  module MetadataValues
    class Boolean < MetadataValue
      def text
        boolean_value ? 'yes' : 'no'
      end

      def text=(val)
        # Set the "text" of this metadata value to *true* if the given value is
        # true and it is not one of the strings "no" and "false"; otherwise, set
        # it to false
        self.boolean_value = val && !val.in?('no', 'false')
      end

      # Converts a text value to a value of the type handled by this class
      def self.convert_text_value(value)
        val.in?('no', 'false') ? false : true
      end

      def self.search(query, scope = scoped)
        scope.where('boolean_value = ?', query.in?('true', 'yes'))
      end
    end
  end
end