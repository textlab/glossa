class CreatePreferenceCollections < ActiveRecord::Migration
  def self.up
    create_table :preference_collections do |t|
      t.integer :user_id
      t.integer :page_size
      t.string :context_type
      t.integer :left_context
      t.integer :right_context
      t.integer :skip_total

      t.timestamps
    end
  end

  def self.down
    drop_table :preference_collections
  end
end
