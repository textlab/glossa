# This migration comes from rglossa (originally 20130802121247)
class RemoveDefaultMaxHitsFromCorpus < ActiveRecord::Migration
  def change
    remove_column :rglossa_corpora, :default_max_hits
  end
end
