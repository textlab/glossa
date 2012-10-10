class MetadataCategoryShortList < MetadataCategory
  def as_json(options = {})
    std_opts = { include: :values }
    super(std_opts.merge(options))
  end
end