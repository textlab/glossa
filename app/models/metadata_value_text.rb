class MetadataValueText < MetadataValue
  def value
    text_value
  end

  def value=(val)
    self.text_value = val
  end
end
