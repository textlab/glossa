# Represents the fact that the possible values of a particular metadata
# catagory is constrained by a selection of values in another category. For
# instance, the set of possible book titles may be constrained by a set of
# selected autorhs.

class Rglossa::MetadataConstraint < ActiveRecord::Base
  # attr_accessible :title, :body

  belongs_to :constrained_category,  class_name: 'MetadataCategory'
  belongs_to :constraining_category, class_name: 'MetadataCategory'
end
