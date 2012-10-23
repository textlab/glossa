module LocalizationSupport

  def localized_attribute(attribute_name)
    # Attributes that start with a colon should be localized; others should just be
    # returned as is
    attr = self[attribute_name]
    attr.start_with?(':') ? I18n.t(attr[1..-1]) : attr
  end

end