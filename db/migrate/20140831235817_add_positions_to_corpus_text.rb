class AddPositionsToCorpusText < ActiveRecord::Migration
  def change
    add_column :rglossa_corpus_texts, :positions, :text
  end
end
