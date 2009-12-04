class LanguageConfig < ActiveRecord::Base
  belongs_to :corpus
  validates_presence_of :corpus_id

  validates_presence_of :name

  TAGGERS = {
          :obt => {
                  :command => 'vislcg3',
          },
          :treetagger => {
                  :command => 'treetagger'
          }
  }
end
