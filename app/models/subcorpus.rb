class Subcorpus < ActiveRecord::Base
  has_and_belongs_to_many :corpus_texts
end
