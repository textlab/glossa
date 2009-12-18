class CreateCorpusTextsSubcorpora < ActiveRecord::Migration
  def self.up
    create_table :corpus_texts_subcorpora, :id => false do |t|
      t.integer :corpus_text_id, :null => false
      t.integer :subcorpus_id, :null => false
    end
  end

  def self.down
    drop_table :corpus_texts_subcorpora
  end
end
