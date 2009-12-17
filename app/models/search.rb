class Search < ActiveRecord::Base
  belongs_to :user
  validates_presence_of :user_id
  
  serialize :queries, Array
  serialize :search_options, Hash
  serialize :metadata_selection, Hash
end
