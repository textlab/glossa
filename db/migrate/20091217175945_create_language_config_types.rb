class CreateLanguageConfigTypes < ActiveRecord::Migration
  def self.up
    create_table :language_config_types do |t|
      t.string :name
      t.string :tagger

      t.timestamps
    end
  end

  def self.down
    drop_table :language_config_types
  end
end
