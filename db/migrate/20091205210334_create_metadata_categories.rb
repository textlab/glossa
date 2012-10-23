class CreateMetadataCategories < ActiveRecord::Migration
  def up
    create_table :metadata_categories do |t|
      t.belongs_to :corpus
      t.string :name, null: false
      t.string :category_type, null: false
      t.string :value_type, null: false

      t.timestamps

      MetadataCategory.create_translation_table!(name: :string)
    end

  def down
    drop_table :metadata_categories
    MetadataCategory.drop_translation_table!
  end
  end
end
