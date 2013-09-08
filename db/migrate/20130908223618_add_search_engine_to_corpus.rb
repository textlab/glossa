class AddSearchEngineToCorpus < ActiveRecord::Migration
  def change
    add_column :rglossa_corpora, :search_engine, :string
  end
end
