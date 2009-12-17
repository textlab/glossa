class Search < ActiveRecord::Base
  serialize :queries, Array
  serialize :search_options, Hash
  serialize :metadata_selection, Hash
end
