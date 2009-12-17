class CreateCorporaLanguageConfigs < ActiveRecord::Migration
  def self.up
    create_table :corpora_language_configs do |t|
      t.integer :corpus_id, :null => false
      t.integer :language_config_id, :null => false

      t.timestamps
    end
  end

  def self.down
    drop_table :corpora_language_configs
  end
end
