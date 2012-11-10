class CreateCorpusTexts < ActiveRecord::Migration
  def change
    create_table :corpus_texts do |t|
      t.integer :startpos, limit: 8  # limit = 8 means bigint
      t.integer :endpos,   limit: 8

      t.timestamps
    end
  end
end
