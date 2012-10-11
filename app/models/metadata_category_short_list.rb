class MetadataCategoryShortList < MetadataCategory

  # Customize the hash representation used by to_json (overriding as_json does
  # not work with associations)
  def serializable_hash(options = {})
    std_opts = { include: :values }
    super(std_opts.merge(options || {}))
  end
end