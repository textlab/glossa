class CreateRglossaMetadataCategories < ActiveRecord::Migration
  def up
    create_table :rglossa_metadata_categories do |t|
      t.belongs_to :corpus,    null: false
      t.string :short_name,    null: false
      t.string :category_type, null: false
      t.string :value_type,    null: false

      t.timestamps

      Rglossa::MetadataCategory.create_translation_table!(name: :string)
    end

  def down
    drop_table :rglossa_metadata_categories
    Rglossa::MetadataCategory.drop_translation_table!
  end
  end
end
