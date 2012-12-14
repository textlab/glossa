require 'globalize3'

module Rglossa
  class Corpus < ActiveRecord::Base
    attr_accessible :locale, :name, :short_name
    translates :name, fallbacks_for_empty_translations: true
    validates_presence_of :name

    has_many :metadata_categories, dependent: :destroy, order: :name
  end
end