require 'globalize3'

class Rglossa::Corpus < ActiveRecord::Base
  translates :name, fallbacks_for_empty_translations: true
  validates_presence_of :name

  has_many :metadata_categories, dependent: :destroy, order: :name
end
