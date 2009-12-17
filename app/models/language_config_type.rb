class LanguageConfigType < ActiveRecord::Base
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
