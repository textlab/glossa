class CreateLanguageConfigs < ActiveRecord::Migration
  def self.up
    create_table :language_configs do |t|
      t.integer :corpus_id
      t.string :name

      t.timestamps
    end
  end

  def self.down
    drop_table :language_configs
  end
end
