class CreateCorpusTexts < ActiveRecord::Migration
  def change
    create_table :corpus_texts do |t|
      t.integer :language_config_id
      t.string :uri

      t.timestamps
    end
  end
end
