class CreateRglossaDeletedHits < ActiveRecord::Migration
  def change
    create_table :rglossa_deleted_hits do |t|
      t.integer :search_id, null: false

      t.timestamps
    end
  end
end
