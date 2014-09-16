# This migration comes from rglossa (originally 20140831235817)
class AddPositionsToCorpusText < ActiveRecord::Migration
  def change
    add_column :rglossa_corpus_texts, :positions, :text
  end
end
