class Corpus < ActiveRecord::Base
  has_many :language_configs

  validates_presence_of :name
end
