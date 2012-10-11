class MetadataValueBoolean < MetadataValue
  def text
    boolean_value ? 'yes' : 'no'
  end

  def text=(val)
    # Set the "text" of this metadata value to *true* if the given value is
    # true and it is not one of the strings "no" and "false"; otherwise, set
    # it to false
    self.boolean_value = val && !val.in?('no', 'false')
  end
end
