class CreateRglossaMetadataValues < ActiveRecord::Migration
  def change
    create_table :rglossa_metadata_values do |t|
      t.belongs_to :metadata_category, null: false
      t.string :type, null: false
      t.text :text_value
      t.integer :integer_value
      t.boolean :boolean_value
    end
  end
end
