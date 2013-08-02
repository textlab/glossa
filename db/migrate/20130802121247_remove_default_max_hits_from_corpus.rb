class RemoveDefaultMaxHitsFromCorpus < ActiveRecord::Migration
  def change
    remove_column :rglossa_corpora, :default_max_hits
  end
end
