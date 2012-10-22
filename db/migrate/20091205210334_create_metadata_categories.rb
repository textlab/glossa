class CreateMetadataCategories < ActiveRecord::Migration
  def change
    create_table :metadata_categories do |t|
      t.belongs_to :corpus
      t.string :name, null: false
      t.string :category_type, null: false
      t.string :value_type, null: false

      t.timestamps
    end
  end
end
