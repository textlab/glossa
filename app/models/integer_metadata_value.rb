class IntegerMetadataValue < MetadataValue
  def value
    integer_value
  end

  def value=(val)
    self.integer_value = val
  end
end
