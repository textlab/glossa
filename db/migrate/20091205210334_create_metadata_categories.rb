class CreateMetadataCategories < ActiveRecord::Migration
  def self.up
    create_table :metadata_categories do |t|
      t.belongs_to :corpus
      t.string :name, null: false
      t.string :category_type, null: false
      t.string :value_type, null: false

      t.timestamps
    end
  end

  def self.down
    drop_table :metadata_categories
  end
end
