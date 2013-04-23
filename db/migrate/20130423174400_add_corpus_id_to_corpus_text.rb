class AddCorpusIdToCorpusText < ActiveRecord::Migration
  def change
    # Breaks db normalization, but lets us list the texts belonging to a corpus without going
    # through corpus->metadata_categories->metadata_values->corpus_texts
    add_column :rglossa_corpus_texts, :corpus_id, :integer
  end
end
