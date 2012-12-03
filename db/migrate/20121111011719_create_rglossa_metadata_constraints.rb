class CreateRglossaMetadataConstraints < ActiveRecord::Migration
  def change
    create_table :rglossa_metadata_constraints do |t|
      t.integer :constrained_category_id
      t.integer :constraining_category_id

      t.timestamps
    end
  end
end
