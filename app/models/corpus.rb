class Corpus < ActiveRecord::Base
  has_many :metadata_categories, dependent: :destroy

  validates_presence_of :name
end
