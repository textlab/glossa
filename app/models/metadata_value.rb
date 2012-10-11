class MetadataValue < ActiveRecord::Base
  belongs_to :metadata_category
  validates_presence_of :metadata_category_id

  # Customize the hash representation used by to_json (overriding as_json does
  # not work with associations)
  def serializable_hash(options = {})
    std_opts = { only: [:id], methods: :text }
    super(std_opts.merge(options || {}))
  end
end
