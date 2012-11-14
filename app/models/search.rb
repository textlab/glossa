class Search < ActiveRecord::Base
  belongs_to :user
  has_many :deleted_hits, dependent: :destroy

  serialize :queries, Array
  serialize :search_options, Hash
  serialize :metadata_selection, Hash
end
