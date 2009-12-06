class CreateMetadataCategories < ActiveRecord::Migration
  def self.up
    create_table :metadata_categories do |t|
      t.string :name, :null => false
      t.string :fieldtype, :null => false
      t.string :selector

      t.timestamps
    end
  end

  def self.down
    drop_table :metadata_categories
  end
end
