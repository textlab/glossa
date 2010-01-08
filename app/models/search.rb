class Search < ActiveRecord::Base
  belongs_to :owner, :class_name => User
  validates_presence_of :owner_id

  serialize :queries, Array
  serialize :search_options, Hash
  serialize :metadata_selection, Hash
end
