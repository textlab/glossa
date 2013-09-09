# This migration comes from rglossa (originally 20130908223618)
class AddSearchEngineToCorpus < ActiveRecord::Migration
  def change
    add_column :rglossa_corpora, :search_engine, :string
  end
end
