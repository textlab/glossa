class Rglossa::MetadataValueInteger < MetadataValue
  def text
    integer_value.to_s
  end

  def text=(val)
    self.integer_value = val.to_i
  end
end
