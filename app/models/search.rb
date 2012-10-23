class Search < ActiveRecord::Base
  belongs_to :owner, :class_name => User

  serialize :queries, Array
  serialize :search_options, Hash
  serialize :metadata_selection, Hash
end
