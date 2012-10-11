class MetadataCategory < ActiveRecord::Base
  belongs_to :corpus
  has_many   :values, class_name: 'MetadataValue', dependent: :destroy

  validates_presence_of :name
  validates_presence_of :value_type

  # Customize the hash representation used by to_json (overriding as_json does
  # not work with associations)
  def serializable_hash(options = {})
    std_opts = { only: [:id, :name, :value_type], methods: :category_type }
    super(std_opts.merge(options || {}))
  end

  def category_type
    # Take the contents of the STI type column and yield something simpler
    # that is suitable for the JSON returned to the client
    type[/MetadataCategory(.*)/, 1].downcase
  end
end
