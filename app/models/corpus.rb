class Corpus < ActiveRecord::Base
  has_many :metadata_categories, dependent: :destroy, order: :name

  validates_presence_of :name
end
