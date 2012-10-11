class Corpus < ActiveRecord::Base
  has_many :metadata_categories, dependent: :destroy

  validates_presence_of :name

  # Customize the hash representation used by to_json (overriding as_json does
  # not work with associations)
  def serializable_hash(options = {})
    std_opts = { only: [:id, :name], include: :metadata_categories }
    super(std_opts.merge(options || {}))
  end
end
