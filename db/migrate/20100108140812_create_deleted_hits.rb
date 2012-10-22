class CreateDeletedHits < ActiveRecord::Migration
  def change
    create_table :deleted_hits do |t|
      t.integer :search_id

      t.timestamps
    end
  end
end
