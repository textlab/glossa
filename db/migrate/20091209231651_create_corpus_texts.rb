class CreateCorpusTexts < ActiveRecord::Migration
  def self.up
    create_table :corpus_texts do |t|
      t.integer :language_config_id

      t.timestamps
    end
  end

  def self.down
    drop_table :corpus_texts
  end
end
