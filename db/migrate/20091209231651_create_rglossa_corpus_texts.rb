class CreateRglossaCorpusTexts < ActiveRecord::Migration
  def change
    create_table :rglossa_corpus_texts do |t|
      t.integer :startpos, limit: 8  # limit = 8 means bigint
      t.integer :endpos,   limit: 8

      t.timestamps
    end
  end
end
