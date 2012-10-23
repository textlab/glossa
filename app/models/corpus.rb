class Corpus < ActiveRecord::Base
  include LocalizationSupport
  has_paper_trail

  has_many :metadata_categories, dependent: :destroy, order: :name

  validates_presence_of :name

  def name
    localized_attribute(:name)
  end
end
