class CreateSearches < ActiveRecord::Migration
  def change
    create_table :searches do |t|
      t.integer :user_id
      t.text :queries, null: false
      t.text :search_options
      t.text :metadata_selection

      t.timestamps
    end
  end
end
