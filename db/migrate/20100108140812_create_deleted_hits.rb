class CreateDeletedHits < ActiveRecord::Migration
  def self.up
    create_table :deleted_hits do |t|
      t.integer :search_id

      t.timestamps
    end
  end

  def self.down
    drop_table :deleted_hits
  end
end
