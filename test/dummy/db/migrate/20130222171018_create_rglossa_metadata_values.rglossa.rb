# This migration comes from rglossa (originally 20091223175749)
class CreateRglossaMetadataValues < ActiveRecord::Migration
  def change
    create_table :rglossa_metadata_values do |t|
      t.belongs_to :metadata_category
      t.string :type
      t.text :text_value
      t.integer :integer_value
      t.boolean :boolean_value
    end
  end
end
